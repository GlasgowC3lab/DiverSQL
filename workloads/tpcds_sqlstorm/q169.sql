WITH date_bounds AS (
  SELECT d_date_sk
  FROM date_dim
  WHERE d_year = 2001
),
sales_union AS (
  SELECT cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_sold_date_sk AS date_sk,
         cs.cs_net_profit AS net_profit,
         cs.cs_ext_discount_amt AS discount,
         cs.cs_quantity AS quantity,
         cs.cs_item_sk AS item_sk,
         cs.cs_order_number AS order_number,
         'catalog' AS channel,
         cs.cs_call_center_sk AS call_center_sk
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_bounds)

  UNION ALL

  SELECT ss.ss_customer_sk AS customer_sk,
         ss.ss_sold_date_sk AS date_sk,
         ss.ss_net_profit AS net_profit,
         ss.ss_ext_discount_amt AS discount,
         ss.ss_quantity AS quantity,
         ss.ss_item_sk AS item_sk,
         ss.ss_ticket_number AS order_number,
         'store' AS channel,
         NULL AS call_center_sk
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_bounds)

  UNION ALL

  SELECT ws.ws_bill_customer_sk AS customer_sk,
         ws.ws_sold_date_sk AS date_sk,
         ws.ws_net_profit AS net_profit,
         ws.ws_ext_discount_amt AS discount,
         ws.ws_quantity AS quantity,
         ws.ws_item_sk AS item_sk,
         ws.ws_order_number AS order_number,
         'web' AS channel,
         NULL AS call_center_sk
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_bounds)
),
customer_agg AS (
  SELECT s.customer_sk,
         COUNT(DISTINCT s.order_number) AS orders_cnt,
         SUM(s.net_profit) AS total_profit,
         SUM(s.discount) AS total_discount,
         SUM(s.quantity) AS total_quantity,
         MIN(s.date_sk) AS first_purchase_sk,
         MAX(s.date_sk) AS last_purchase_sk,
         COUNT(DISTINCT s.item_sk) AS distinct_items,
         MIN(COALESCE(s.call_center_sk, -1)) AS any_call_center_sk
  FROM sales_union s
  GROUP BY s.customer_sk
),
customer_details AS (
  SELECT c.c_customer_sk,
         COALESCE(TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name), 'UNKNOWN') AS full_name,
         c.c_preferred_cust_flag,
         c.c_birth_year,
         CASE
           WHEN c.c_preferred_cust_flag = 'Y' THEN 'VIP'
           ELSE 'REG'
         END AS customer_type,
         COALESCE(da.ca_city, 'UNKNOWN') AS city,
         COALESCE(da.ca_state, 'UNKNOWN') AS state,
         COALESCE(cd.cd_gender, 'U') AS gender,
         COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
  FROM customer c
  LEFT JOIN customer_address da ON c.c_current_addr_sk = da.ca_address_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
call_center_info AS (
  SELECT cc.cc_call_center_sk,
         cc.cc_name,
         cc.cc_manager,
         cc.cc_state,
         cc.cc_gmt_offset
  FROM call_center cc
),
final AS (
  SELECT
    ca.full_name,
    ca.customer_type,
    ca.city,
    ca.state,
    ca.gender,
    ca.buy_potential,
    agg.orders_cnt,
    agg.total_profit,
    agg.total_discount,
    agg.total_quantity,
    agg.distinct_items,
    d_first.d_date AS first_purchase_date,
    d_last.d_date AS last_purchase_date,
    COALESCE(cci.cc_name, 'N/A') AS call_center_name,
    COALESCE(cci.cc_manager, 'N/A') AS call_center_manager,
    ROW_NUMBER() OVER (ORDER BY agg.total_profit DESC) AS profit_rank,
    CASE
      WHEN agg.total_profit > 0 AND agg.total_profit / NULLIF(agg.total_quantity, 0) > 100 THEN 'HIGH'
      WHEN agg.total_profit > 0 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_category,
    (SELECT su.channel
     FROM sales_union su
     WHERE su.customer_sk = agg.customer_sk
       AND su.date_sk = agg.last_purchase_sk
     ORDER BY su.date_sk DESC
     LIMIT 1) AS last_purchase_channel
  FROM customer_agg agg
  JOIN customer_details ca ON agg.customer_sk = ca.c_customer_sk
  LEFT JOIN date_dim d_first ON agg.first_purchase_sk = d_first.d_date_sk
  LEFT JOIN date_dim d_last ON agg.last_purchase_sk = d_last.d_date_sk
  LEFT JOIN call_center_info cci ON agg.any_call_center_sk = cci.cc_call_center_sk
  WHERE agg.total_profit IS NOT NULL
)
SELECT *
FROM final
WHERE profit_rank <= 10
ORDER BY profit_rank
