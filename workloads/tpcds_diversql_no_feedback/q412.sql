WITH
  agg_ret AS (
    SELECT
      cr_catalog_page_sk,
      cr_ship_mode_sk,
      cr_returned_date_sk,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_return_quantity) AS total_return_qty,
      COUNT(*) AS return_cnt,
      AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 20.00
      AND cr_return_quantity >= 2
      AND cr_returned_date_sk BETWEEN 2451000 AND 2452000
      AND cr_ship_mode_sk IN (
        SELECT sm_ship_mode_sk
        FROM ship_mode
        WHERE sm_contract = 'GNJr3g5i7oorKqtX'
      )
    GROUP BY cr_catalog_page_sk, cr_ship_mode_sk, cr_returned_date_sk
  ),
  filtered_pages AS (
    SELECT cp_catalog_page_sk
    FROM catalog_page
    WHERE cp_department = 'Electronics'
      AND cp_catalog_number IN (14, 15)
      AND cp_catalog_page_number BETWEEN 10 AND 20
      AND cp_type = 'PROMO'
      AND cp_description LIKE '%discount%'
  ),
  intersect_keys AS (
    SELECT cp_catalog_page_sk FROM filtered_pages
    INTERSECT
    SELECT cr_catalog_page_sk FROM agg_ret
  )
SELECT
  d.d_year,
  d.d_month_seq,
  sm.sm_ship_mode_id,
  SUM(agg.total_return_amount) AS sum_return_amount,
  SUM(agg.total_return_qty) AS sum_return_qty,
  COUNT(DISTINCT agg.cr_catalog_page_sk) AS distinct_pages,
  AVG(agg.avg_return_amount) AS avg_of_avg_return,
  MIN(agg.total_return_amount) AS min_return_amount,
  MAX(agg.total_return_amount) AS max_return_amount
FROM agg_ret agg
JOIN intersect_keys ik ON agg.cr_catalog_page_sk = ik.cp_catalog_page_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = agg.cr_catalog_page_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = agg.cr_ship_mode_sk
JOIN date_dim d ON d.d_date_sk = agg.cr_returned_date_sk
WHERE cp.cp_description LIKE '%summer%'
  AND sm.sm_type = 'AIR'
  AND d.d_dow = 5
  AND d.d_holiday = 'N'
  AND d.d_current_week = 'N'
  AND cp.cp_catalog_page_number <> 12
GROUP BY d.d_year, d.d_month_seq, sm.sm_ship_mode_id
ORDER BY sum_return_amount DESC
LIMIT 50
