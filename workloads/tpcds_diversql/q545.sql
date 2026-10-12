WITH
  store_customers AS (
    SELECT ss.ss_customer_sk AS c_customer_sk
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2451915
  ),
  web_customers AS (
    SELECT ws.ws_bill_customer_sk AS c_customer_sk
    FROM web_sales ws
    TABLESAMPLE BERNOULLI (10)
    WHERE ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915
  ),
  common_customers AS (
    SELECT c_customer_sk FROM store_customers
    INTERSECT
    SELECT c_customer_sk FROM web_customers
  )
SELECT
  c.c_customer_id,
  COUNT(DISTINCT ss.ss_ticket_number)               AS store_order_cnt,
  COUNT(DISTINCT ws.ws_order_number)                AS web_order_cnt,
  SUM(DISTINCT ss.ss_ext_sales_price)               AS store_sales_distinct_sum,
  SUM(DISTINCT ws.ws_ext_sales_price)               AS web_sales_distinct_sum
FROM
  common_customers cc
  JOIN customer c ON c.c_customer_sk = cc.c_customer_sk
  LEFT JOIN store_sales ss
    ON ss.ss_customer_sk = cc.c_customer_sk
   AND ss.ss_sold_date_sk BETWEEN 2451910 AND 2451915
  LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = cc.c_customer_sk
   AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915
GROUP BY
  c.c_customer_id
ORDER BY
  store_order_cnt DESC,
  web_order_cnt DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
