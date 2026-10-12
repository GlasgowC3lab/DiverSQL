WITH
store_sales_cte AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    d.d_year,
    d.d_quarter_name,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    'store' AS sales_channel,
    ss.ss_ticket_number AS order_id,
    CASE 
      WHEN ss.ss_ext_sales_price = 0 THEN NULL 
      ELSE ss.ss_ext_discount_amt / ss.ss_ext_sales_price 
    END AS discount_rate
  FROM store_sales ss
  LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
),
web_sales_cte AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    d.d_year,
    d.d_quarter_name,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    'web' AS sales_channel,
    ws.ws_order_number AS order_id,
    CASE 
      WHEN ws.ws_ext_sales_price = 0 THEN NULL 
      ELSE ws.ws_ext_discount_amt / ws.ws_ext_sales_price 
    END AS discount_rate
  FROM web_sales ws
  LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
),
combined_sales AS (
  SELECT * FROM store_sales_cte
  UNION ALL
  SELECT * FROM web_sales_cte
),
aggregated AS (
  SELECT
    customer_sk,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    COALESCE(ca_city, 'UNKNOWN') AS city,
    COALESCE(ca_state, 'UNKNOWN') AS state,
    d_year,
    d_quarter_name,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    AVG(discount_rate) AS avg_discount_rate,
    COUNT(*) AS txn_count
  FROM combined_sales cs
  GROUP BY
    customer_sk,
    c_first_name,
    c_last_name,
    ca_city,
    ca_state,
    d_year,
    d_quarter_name
),
ranked_sales AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS sales_rank
  FROM aggregated
),
top_customers AS (
  SELECT *
  FROM ranked_sales
  WHERE sales_rank <= 10
),
store_returns_agg AS (
  SELECT
    sr.sr_customer_sk AS customer_sk,
    SUM(sr.sr_return_amt + sr.sr_return_tax) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY sr.sr_customer_sk
),
correlated_sub AS (
  SELECT
    tc.customer_sk,
    tc.full_name,
    tc.city,
    tc.state,
    tc.d_year,
    tc.d_quarter_name,
    tc.total_net_paid,
    tc.total_net_profit,
    tc.avg_discount_rate,
    tc.txn_count,
    tc.sales_rank,
    (SELECT AVG(cs.net_paid) FROM combined_sales cs WHERE cs.customer_sk = tc.customer_sk) AS avg_order_value
  FROM top_customers tc
)
SELECT
  cs.full_name,
  cs.city,
  cs.state,
  cs.d_year,
  cs.d_quarter_name,
  cs.total_net_paid,
  cs.total_net_profit,
  ROUND(cs.avg_discount_rate * 100, 2) AS avg_discount_pct,
  cs.txn_count,
  cs.sales_rank,
  COALESCE(sr.total_return_amount, 0) AS total_return_amount,
  COALESCE(sr.return_cnt, 0) AS return_cnt,
  cs.avg_order_value,
  CASE WHEN cs.total_net_paid > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
  CONCAT('CUST_', CAST(cs.customer_sk AS VARCHAR)) AS customer_code
FROM correlated_sub cs
LEFT JOIN store_returns_agg sr ON cs.customer_sk = sr.customer_sk
WHERE cs.total_net_paid IS NOT NULL
ORDER BY cs.total_net_paid DESC
LIMIT 100
