WITH customer_sales AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_birth_country,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(*) AS sales_rows
  FROM web_sales ws
  INNER JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_type = 'product'
    AND ws.ws_sold_date_sk BETWEEN 2452500 AND 2452600
    AND c.c_birth_country IN ('MEXICO', 'CHILE')
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY
    c.c_customer_sk,
    c.c_customer_id,
    c.c_birth_country,
    c.c_first_name,
    c.c_last_name
),

ranked_customers AS (
  SELECT
    cs.*, 
    ROW_NUMBER() OVER (PARTITION BY cs.c_birth_country ORDER BY cs.total_net_profit DESC) AS rank_in_country
  FROM customer_sales cs
)

SELECT
  rc.c_birth_country,
  rc.c_customer_id,
  rc.c_first_name,
  rc.c_last_name,
  rc.total_net_profit,
  rc.total_quantity,
  rc.avg_discount,
  rc.distinct_orders,
  rc.rank_in_country
FROM ranked_customers rc
WHERE rc.rank_in_country <= 5
ORDER BY rc.c_birth_country, rc.rank_in_country
