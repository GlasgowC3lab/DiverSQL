WITH
  daytime AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_hour BETWEEN 9 AND 17
  ),
  dinner AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_meal_time = 'Dinner'
  ),
  valid_times AS (
    SELECT t_time_sk FROM daytime
    INTERSECT
    SELECT t_time_sk FROM dinner
  ),
  agg_sales AS (
    SELECT
      ss_store_sk,
      ss_sold_time_sk,
      ss_hdemo_sk,
      SUM(ss_net_paid) AS total_net_paid,
      COUNT(*) AS cnt_sales
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_store_sk, ss_sold_time_sk, ss_hdemo_sk
  ),
  catalog_ret_detail AS (
    SELECT
      cr_returned_time_sk,
      cr_catalog_page_sk,
      cr_ship_mode_sk,
      cr_warehouse_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_returned_time_sk, cr_catalog_page_sk, cr_ship_mode_sk, cr_warehouse_sk
  ),
  web_ret_detail AS (
    SELECT
      wr_returned_time_sk,
      wr_web_page_sk,
      SUM(wr_return_amt) AS total_return_amount,
      COUNT(*) AS cnt_returns
    FROM web_returns
    WHERE wr_return_quantity > 0
    GROUP BY wr_returned_time_sk, wr_web_page_sk
  )
SELECT
  s.s_store_id,
  s.s_store_name,
  s.s_state,
  cp.cp_department,
  sm.sm_type,
  ib.ib_upper_bound,
  wp.wp_char_count,
  SUM(a.total_net_paid) AS store_total_sales,
  SUM(COALESCE(cr.total_return_amount, 0)) AS total_catalog_returns,
  SUM(COALESCE(wr.total_return_amount, 0)) AS total_web_returns,
  SUM(a.cnt_sales) AS total_sales_transactions,
  MIN(a.total_net_paid) AS min_sales_amount,
  MAX(a.total_net_paid) AS max_sales_amount
FROM agg_sales a
JOIN store s
  ON a.ss_store_sk = s.s_store_sk
JOIN valid_times vt
  ON a.ss_sold_time_sk = vt.t_time_sk
JOIN household_demographics hd
  ON a.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_ret_detail cr
  ON cr.cr_returned_time_sk = vt.t_time_sk
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_ret_detail wr
  ON wr.wr_returned_time_sk = vt.t_time_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE s.s_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND sm.sm_type = 'AIR'
  AND ib.ib_upper_bound >= 50000
  AND wp.wp_char_count > 3000
GROUP BY
  s.s_store_id,
  s.s_store_name,
  s.s_state,
  cp.cp_department,
  sm.sm_type,
  ib.ib_upper_bound,
  wp.wp_char_count
ORDER BY store_total_sales DESC
LIMIT 100
