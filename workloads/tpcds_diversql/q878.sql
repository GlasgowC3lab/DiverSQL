WITH
  sampled_sales AS (
    SELECT
      ss_sold_date_sk,
      ss_sold_time_sk,
      ss_customer_sk,
      ss_addr_sk,
      ss_store_sk,
      ss_net_paid
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),

  full_store_date AS (
    SELECT
      s.s_store_sk,
      s.s_store_id,
      s.s_state,
      d.d_date_sk,
      d.d_year
    FROM store s
    FULL OUTER JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
  ),

  intersect_customers AS (
    SELECT c.c_customer_id
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    INTERSECT
    SELECT c2.c_customer_id
    FROM customer c2
    JOIN web_page wp ON wp.wp_customer_sk = c2.c_customer_sk
    WHERE wp.wp_type = 'content'
  ),

  sales_agg AS (
    SELECT
      s.s_store_id,
      d.d_year,
      SUM(ss.ss_net_paid) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_customer_id IN (SELECT c_customer_id FROM intersect_customers)
      AND d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_type = 'content'
      )
    GROUP BY ROLLUP (s.s_store_id, d.d_year)
  ),

  returns_agg AS (
    SELECT
      w.w_warehouse_id,
      d.d_year,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'TX'
      AND cr.cr_return_tax > 20
    GROUP BY ROLLUP (w.w_warehouse_id, d.d_year)
  )

SELECT
  COALESCE(sa.s_store_id, fsd.s_store_id, 'ALL_STORES') AS store_id,
  COALESCE(sa.d_year, fsd.d_year, 0) AS year,
  sa.total_sales,
  ra.total_return_amount,
  (sa.total_sales - COALESCE(ra.total_return_amount, 0)) AS net_total,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(sa.d_year, fsd.d_year) ORDER BY sa.total_sales DESC) AS sales_rank,
  CASE WHEN sa.total_sales > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category
FROM sales_agg sa
LEFT JOIN returns_agg ra ON ra.d_year = sa.d_year
LEFT JOIN full_store_date fsd ON fsd.s_store_id = sa.s_store_id
ORDER BY year DESC, sales_rank
LIMIT 100
