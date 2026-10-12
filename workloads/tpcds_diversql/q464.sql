WITH
  -- First filtered join chain
  agg_a AS (
    SELECT
      cr.cr_warehouse_sk AS w_warehouse_sk,
      cr.cr_catalog_page_sk AS cp_catalog_page_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_quantity,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price > 50
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_count >= 2
      AND cp.cp_catalog_number IN (3, 9, 11)
      AND w.w_city = 'Spring'
      AND cr.cr_return_amount > 20
      AND cr.cr_return_quantity > 0
    GROUP BY cr.cr_warehouse_sk, cr.cr_catalog_page_sk
  ),
  -- Second filtered join chain (different predicates)
  agg_b AS (
    SELECT
      cr.cr_warehouse_sk AS w_warehouse_sk,
      cr.cr_catalog_page_sk AS cp_catalog_page_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_quantity,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price BETWEEN 30 AND 70
      AND cd.cd_marital_status = 'S'
      AND cd.cd_dep_college_count >= 3
      AND cp.cp_catalog_number IN (2, 15)
      AND w.w_city = 'Center'
      AND cr.cr_return_amount > 10
      AND cr.cr_return_quantity > 1
    GROUP BY cr.cr_warehouse_sk, cr.cr_catalog_page_sk
  ),
  -- Keep only keys present in both aggregated sets
  intersect_keys AS (
    SELECT w_warehouse_sk, cp_catalog_page_sk FROM agg_a
    INTERSECT
    SELECT w_warehouse_sk, cp_catalog_page_sk FROM agg_b
  ),
  filtered_a AS (
    SELECT a.*
    FROM agg_a a
    WHERE (a.w_warehouse_sk, a.cp_catalog_page_sk) IN (SELECT w_warehouse_sk, cp_catalog_page_sk FROM intersect_keys)
  ),
  filtered_b AS (
    SELECT b.*
    FROM agg_b b
    WHERE (b.w_warehouse_sk, b.cp_catalog_page_sk) IN (SELECT w_warehouse_sk, cp_catalog_page_sk FROM intersect_keys)
  ),
  -- Union the two filtered results (deduplicated)
  unioned AS (
    SELECT * FROM filtered_a
    UNION DISTINCT
    SELECT * FROM filtered_b
  ),
  -- Rank within each warehouse
  ranked AS (
    SELECT
      u.*,
      RANK() OVER (PARTITION BY w_warehouse_sk ORDER BY total_return_amount DESC) AS rank_in_warehouse
    FROM unioned u
  )
SELECT
  r.w_warehouse_sk,
  r.cp_catalog_page_sk,
  r.total_return_amount,
  r.total_quantity,
  r.return_cnt,
  r.rank_in_warehouse,
  lt.avg_return_amount_per_warehouse
FROM ranked r
CROSS JOIN LATERAL (
  SELECT AVG(total_return_amount) AS avg_return_amount_per_warehouse
  FROM ranked r2
  WHERE r2.w_warehouse_sk = r.w_warehouse_sk
) lt
ORDER BY r.rank_in_warehouse
LIMIT 100
