WITH
  store_items AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_net_paid,
      i.i_item_desc,
      i.i_product_name,
      i.i_brand,
      s.s_store_name,
      d.d_year,
      REGEXP_EXTRACT(i.i_item_desc, '(\\d+)') AS numeric_part,
      CASE WHEN ss.ss_net_paid > 1000 THEN 'High' ELSE 'Low' END AS revenue_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '\\d')
      AND s.s_store_name LIKE '%Store%'
  ),
  lateral_calc AS (
    SELECT
      si.*, 
      t.extracted_code
    FROM store_items si
    CROSS JOIN LATERAL (
      SELECT REGEXP_EXTRACT(si.i_item_desc, '([A-Z]{2})') AS extracted_code
    ) t
  ),
  store_set_a AS (
    SELECT DISTINCT ss_store_sk FROM lateral_calc WHERE revenue_category = 'High'
  ),
  store_set_b AS (
    SELECT DISTINCT ss_store_sk FROM lateral_calc WHERE d_year = 2002
  ),
  store_diff AS (
    SELECT ss_store_sk FROM store_set_a
    EXCEPT
    SELECT ss_store_sk FROM store_set_b
  ),
  store_common AS (
    SELECT ss_store_sk FROM store_set_a
    INTERSECT
    SELECT ss_store_sk FROM store_set_b
  ),
  agg_high AS (
    SELECT
      s.s_store_name,
      COUNT(*) AS sales_cnt,
      SUM(lc.ss_net_paid) AS total_paid,
      CONCAT('Region-', SUBSTR(s.s_state, 1, 2)) AS store_region_code
    FROM lateral_calc lc
    JOIN store s ON lc.ss_store_sk = s.s_store_sk
    WHERE lc.ss_store_sk IN (SELECT ss_store_sk FROM store_diff)
    GROUP BY s.s_store_name,
      CONCAT('Region-', SUBSTR(s.s_state, 1, 2))
  ),
  agg_common AS (
    SELECT
      s.s_store_name,
      COUNT(*) AS sales_cnt,
      SUM(lc.ss_net_paid) AS total_paid,
      CONCAT('Region-', SUBSTR(s.s_state, 1, 2)) AS store_region_code
    FROM lateral_calc lc
    JOIN store s ON lc.ss_store_sk = s.s_store_sk
    WHERE lc.ss_store_sk IN (SELECT ss_store_sk FROM store_common)
    GROUP BY s.s_store_name,
      CONCAT('Region-', SUBSTR(s.s_state, 1, 2))
  )
SELECT *
FROM agg_high
UNION
SELECT *
FROM agg_common
ORDER BY total_paid DESC
LIMIT 100
