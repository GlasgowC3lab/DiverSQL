WITH
  sampled_customers AS (
    SELECT *
    FROM customer
    TABLESAMPLE BERNOULLI (10)
    WHERE c_birth_day = 9
      AND c_birth_month = 2
      AND c_birth_year = 1970
      AND c_preferred_cust_flag = 'Y'
  ),
  returned_customers AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk FROM catalog_returns cr
    UNION
    SELECT wr.wr_refunded_customer_sk FROM web_returns wr
  ),
  customers_without_returns AS (
    SELECT sc.c_customer_sk
    FROM sampled_customers sc
    EXCEPT
    SELECT rc.cust_sk FROM returned_customers rc
  )
SELECT
  td.t_shift,
  td.t_sub_shift,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(wr.wr_return_amt) AS total_web_return_amount,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  MIN(ss.ss_net_paid) AS min_net_paid,
  MAX(ss.ss_net_paid) AS max_net_paid
FROM
  store_sales ss
  INNER JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  INNER JOIN sampled_customers sc
    ON ss.ss_customer_sk = sc.c_customer_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = sc.c_customer_sk
   AND cr.cr_returned_time_sk = td.t_time_sk
  FULL OUTER JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
  INNER JOIN customers_without_returns cw
    ON cw.c_customer_sk = sc.c_customer_sk
WHERE
  td.t_hour BETWEEN 9 AND 17
  AND td.t_am_pm = 'PM'
  AND td.t_sub_shift = 'evening'
  AND ss.ss_quantity > 1
  AND ss.ss_sales_price > 20.00
  AND cr.cr_return_quantity IS NOT NULL
  AND wr.wr_return_quantity > 0
  AND cr.cr_fee < 5.00
GROUP BY
  td.t_shift,
  td.t_sub_shift
HAVING
  SUM(ss.ss_ext_sales_price) > 1000
ORDER BY
  total_sales DESC
LIMIT 100
