WITH
  cube_sales AS (
    SELECT
      c.c_customer_sk,
      i.i_category,
      SUM(ws.ws_ext_sales_price) AS sales_amount
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY CUBE (c.c_customer_sk, i.i_category)
  ),

  high_web_customers AS (
    SELECT DISTINCT c_customer_sk
    FROM cube_sales
    WHERE i_category IS NULL
      AND sales_amount > 1000
  ),

  profitable_store_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_net_profit > 500
  ),

  customers_with_returns AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_net_loss > 0
  ),

  web_not_store AS (
    SELECT c_customer_sk FROM high_web_customers
    EXCEPT
    SELECT c_customer_sk FROM profitable_store_customers
  ),

  final_customers AS (
    SELECT c_customer_sk FROM web_not_store
    INTERSECT
    SELECT c_customer_sk FROM customers_with_returns
  )

SELECT
  c.c_customer_id,
  cs.sales_amount AS total_web_sales,
  (
    SELECT COALESCE(SUM(sr.sr_refunded_cash), 0)
    FROM store_returns sr
    WHERE sr.sr_customer_sk = c.c_customer_sk
  ) AS total_refunded_cash
FROM final_customers fc
JOIN customer c ON fc.c_customer_sk = c.c_customer_sk
LEFT JOIN cube_sales cs
  ON cs.c_customer_sk = c.c_customer_sk
  AND cs.i_category IS NULL
ORDER BY cs.sales_amount DESC
LIMIT 100
