WITH ws_sample AS (
  SELECT *
  FROM web_sales
  TABLESAMPLE BERNOULLI (10)
),
base AS (
  SELECT
    c.c_customer_sk,
    d.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS sales_orders
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN ws_sample ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2000
    AND c.c_birth_year BETWEEN 1950 AND 1960
    AND cr.cr_return_amount > 1000
    AND ws.ws_ext_list_price < 20000
    AND wp.wp_type = 'content'
  GROUP BY c.c_customer_sk, d.d_year
)
SELECT
  d_year,
  COUNT(*) AS num_customers,
  AVG(total_return_amount) AS avg_return_amount,
  AVG(total_sales_amount) AS avg_sales_amount,
  AVG(total_return_amount) / NULLIF(AVG(total_sales_amount), 0) AS avg_return_to_sales_ratio
FROM base
WHERE total_return_amount > 5000
GROUP BY d_year
HAVING AVG(total_sales_amount) > 10000
ORDER BY avg_return_to_sales_ratio DESC
