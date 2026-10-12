WITH
  sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
  ),
  base_join AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cp.cp_department,
      d_ret.d_year AS return_year,
      cust_ref.c_customer_id AS refunded_customer,
      cust_ret.c_customer_id AS returning_customer,
      wp.wp_url,
      d_creation.d_year AS creation_year,
      CASE
        WHEN d_ret.d_holiday = 'Y' THEN 'HolidayReturn'
        ELSE 'RegularReturn'
      END AS return_type,
      SUM(cr.cr_return_amount) OVER (
        PARTITION BY cp.cp_department
        ORDER BY d_ret.d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS running_dept_return_amt,
      LAG(cr.cr_return_amount) OVER (
        PARTITION BY cp.cp_department
        ORDER BY d_ret.d_date
      ) AS prev_return_amount
    FROM sampled_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer cust_ref
      ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
    JOIN customer cust_ret
      ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_start
      ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
      ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = cust_ret.c_customer_sk
    JOIN date_dim d_creation
      ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
      ON wp.wp_access_date_sk = d_access.d_date_sk
  ),
  high_value_returns AS (
    SELECT cr_order_number
    FROM sampled_returns
    WHERE cr_return_amount > 1000
  ),
  holiday_returns AS (
    SELECT cr.cr_order_number
    FROM sampled_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
  ),
  intersect_set AS (
    SELECT cr_order_number FROM high_value_returns
    INTERSECT
    SELECT cr_order_number FROM holiday_returns
  ),
  except_set AS (
    SELECT cr_order_number FROM high_value_returns
    EXCEPT
    SELECT cr_order_number FROM holiday_returns
  )
SELECT
  bj.return_year,
  bj.cp_department,
  bj.return_type,
  COUNT(DISTINCT bj.cr_order_number) AS total_orders,
  SUM(bj.cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT iset.cr_order_number) AS intersect_high_holiday,
  COUNT(DISTINCT eset.cr_order_number) AS high_not_holiday
FROM base_join bj
LEFT JOIN intersect_set iset ON bj.cr_order_number = iset.cr_order_number
LEFT JOIN except_set eset ON bj.cr_order_number = eset.cr_order_number
GROUP BY bj.return_year, bj.cp_department, bj.return_type
ORDER BY total_return_amount DESC
LIMIT 100
