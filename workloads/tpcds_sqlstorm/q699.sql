WITH
unified_sales AS (
  SELECT cs.cs_bill_customer_sk AS cust_sk,
         cs.cs_sold_date_sk AS date_sk,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         cs.cs_ext_sales_price AS ext_sales_price,
         cs.cs_quantity AS quantity,
         cs.cs_order_number AS order_number,
         'catalog' AS channel,
         cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_customer_sk AS cust_sk,
         ss.ss_sold_date_sk AS date_sk,
         ss.ss_net_paid AS net_paid,
         ss.ss_net_profit AS net_profit,
         ss.ss_ext_sales_price AS ext_sales_price,
         ss.ss_quantity AS quantity,
         ss.ss_ticket_number AS order_number,
         'store' AS channel,
         ss.ss_promo_sk AS promo_sk
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_bill_customer_sk AS cust_sk,
         ws.ws_sold_date_sk AS date_sk,
         ws.ws_net_paid AS net_paid,
         ws.ws_net_profit AS net_profit,
         ws.ws_ext_sales_price AS ext_sales_price,
         ws.ws_quantity AS quantity,
         ws.ws_order_number AS order_number,
         'web' AS channel,
         ws.ws_promo_sk AS promo_sk
  FROM web_sales ws
),
customer_agg AS (
  SELECT us.cust_sk,
         COUNT(DISTINCT us.order_number) AS orders,
         SUM(us.quantity) AS total_quantity,
         SUM(us.net_paid) AS total_paid,
         SUM(us.net_profit) AS total_profit,
         SUM(us.ext_sales_price) AS total_sales_price,
         MAX(us.date_sk) AS last_sale_date_sk,
         COUNT(DISTINCT us.channel) AS channels_used
  FROM unified_sales us
  GROUP BY us.cust_sk
),
top_customers AS (
  SELECT ca.cust_sk,
         ca.orders,
         ca.total_quantity,
         ca.total_paid,
         ca.total_profit,
         ca.total_sales_price,
         ca.last_sale_date_sk,
         ca.channels_used,
         ROW_NUMBER() OVER (ORDER BY ca.total_profit DESC) AS profit_rank
  FROM customer_agg ca
  WHERE ca.total_paid > 0
),
customer_details AS (
  SELECT c.c_customer_sk,
         c.c_first_name,
         c.c_last_name,
         COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
         ca.ca_city,
         ca.ca_state,
         ca.ca_country,
         CONCAT_WS(', ', c.c_first_name, c.c_last_name) AS full_name
  FROM customer c
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
last_purchase AS (
  SELECT us.cust_sk,
         MAX(d.d_date) AS last_purchase_date
  FROM unified_sales us
  JOIN date_dim d ON us.date_sk = d.d_date_sk
  GROUP BY us.cust_sk
),
promo_usage AS (
  SELECT cs.cs_bill_customer_sk AS cust_sk, p.p_promo_name
  FROM catalog_sales cs
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT ss.ss_customer_sk, p.p_promo_name
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT ws.ws_bill_customer_sk, p.p_promo_name
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
who_is_omni AS (
  SELECT ss_cust.cust_sk
  FROM (SELECT ss_customer_sk AS cust_sk FROM store_sales GROUP BY ss_customer_sk) ss_cust
  INTERSECT
  SELECT ws_cust.cust_sk
  FROM (SELECT ws_bill_customer_sk AS cust_sk FROM web_sales GROUP BY ws_bill_customer_sk) ws_cust
  INTERSECT
  SELECT cs_cust.cust_sk
  FROM (SELECT cs_bill_customer_sk AS cust_sk FROM catalog_sales GROUP BY cs_bill_customer_sk) cs_cust
)
SELECT
  tc.profit_rank,
  cd.c_customer_sk AS customer_sk,
  cd.full_name,
  cd.pref_flag,
  cd.ca_city,
  cd.ca_state,
  cd.ca_country,
  tc.orders,
  tc.total_quantity,
  ROUND(tc.total_paid, 2) AS total_paid,
  ROUND(tc.total_profit, 2) AS total_profit,
  CASE WHEN tc.total_paid = 0 THEN NULL
       ELSE ROUND(tc.total_profit / tc.total_paid, 4)
  END AS profit_margin,
  COALESCE(lp.last_purchase_date, DATE '1900-01-01') AS last_purchase_date,
  COALESCE(pu.p_promo_name, 'No Promo') AS recent_promo,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM store_returns sr
      JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
      WHERE sr.sr_customer_sk = cd.c_customer_sk
        AND dr.d_year = 2002
    ) THEN 'Returned in 2002'
    ELSE 'No Return 2002'
  END AS return_2002_flag,
  CASE
    WHEN (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = cd.c_customer_sk) > 0
    THEN 'Web Returns Exist'
    ELSE 'No Web Returns'
  END AS web_return_flag,
  (SELECT AVG(us2.net_profit)
   FROM unified_sales us2
   JOIN date_dim d2 ON us2.date_sk = d2.d_date_sk
   WHERE us2.cust_sk = cd.c_customer_sk
     AND d2.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31') AS avg_profit_2001,
  CASE
    WHEN tc.channels_used = 3 THEN 'Omni-channel'
    WHEN tc.channels_used = 2 THEN 'Multi-channel'
    ELSE 'Single-channel'
  END AS channel_type,
  CASE WHEN EXISTS (SELECT 1 FROM who_is_omni wo WHERE wo.cust_sk = tc.cust_sk) THEN 'Omni' ELSE 'Not Omni' END AS omni_flag
FROM top_customers tc
LEFT JOIN customer_details cd ON tc.cust_sk = cd.c_customer_sk
LEFT JOIN last_purchase lp ON lp.cust_sk = tc.cust_sk
LEFT JOIN (
  SELECT cust_sk, MIN(p_promo_name) AS p_promo_name
  FROM promo_usage
  GROUP BY cust_sk
) pu ON pu.cust_sk = tc.cust_sk
WHERE tc.profit_rank <= 100
ORDER BY tc.profit_rank
