WITH cust_agg AS (
  SELECT
    ws.ws_bill_customer_sk,
    MIN(ws.ws_sold_date_sk) AS first_sold_date,
    MAX(ws.ws_sold_date_sk) AS last_sold_date,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT CASE WHEN p.p_discount_active = 'Y' THEN p.p_promo_id END) AS active_promo_cnt,
    cd.cd_gender,
    ca.ca_state,
    ca.ca_city,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS discount_status
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  GROUP BY ws.ws_bill_customer_sk, cd.cd_gender, ca.ca_state, ca.ca_city, p.p_discount_active
),
cust_rank AS (
  SELECT
    ws_bill_customer_sk,
    total_net_profit,
    total_quantity,
    avg_discount,
    active_promo_cnt,
    cd_gender,
    ca_state,
    ca_city,
    discount_status,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    LAG(total_net_profit) OVER (ORDER BY total_net_profit DESC) AS previous_profit
  FROM cust_agg
)
SELECT
  ws_bill_customer_sk,
  total_net_profit,
  total_quantity,
  avg_discount,
  active_promo_cnt,
  cd_gender,
  ca_state,
  ca_city,
  discount_status,
  profit_rank,
  previous_profit,
  CASE
    WHEN profit_rank = 1 THEN 'Top Customer'
    WHEN profit_rank <= 10 THEN 'Top 10'
    ELSE 'Other'
  END AS profit_tier
FROM cust_rank
WHERE total_net_profit > 0
ORDER BY profit_rank
LIMIT 50
