WITH
  -- Right outer join retains all dates even if there were no returns
  right_join AS (
    SELECT
      d.d_year,
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      d.d_day_name,
      p.p_promo_name,
      p.p_promo_id,
      CONCAT(p.p_promo_name, ' - ', p.p_promo_id) AS promo_desc,
      SUBSTRING(d.d_day_name, 1, 3) AS day_abbrev
    FROM catalog_returns cr
    RIGHT JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN promotion p
      ON p.p_start_date_sk = d.d_date_sk
     AND p.p_end_date_sk   = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(p.p_promo_name, 'Summer')
      AND p.p_channel_email = 'Y'
      AND d.d_day_name LIKE 'Mon%'
  ),

  -- Full outer join between date_dim and promotion keeps rows from both sides
  full_join AS (
    SELECT
      d.d_year,
      p.p_promo_id,
      p.p_promo_name,
      p.p_cost
    FROM date_dim d
    FULL OUTER JOIN promotion p
      ON p.p_start_date_sk = d.d_date_sk
    WHERE (p.p_cost < 1000 OR d.d_year = 2001)
  ),

  -- Keys that appear in BOTH sub‑queries (INTERSECT)
  intersect_keys AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 2
    INTERSECT
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE p.p_cost > 2000
  ),

  -- Distinct keys from two different selects (UNION)
  union_keys AS (
    SELECT cr.cr_order_number AS key_id
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1500
    UNION
    SELECT p.p_promo_sk AS key_id
    FROM promotion p
    WHERE p.p_cost < 3000
  ),

  -- Aggregation of the right‑joined data
  agg_right AS (
    SELECT
      d_year,
      COUNT(DISTINCT cr_order_number) AS orders_cnt,
      SUM(cr_return_amount)          AS total_return_amount,
      COUNT(*)                       AS rows_cnt,
      CAST(NULL AS BIGINT)          AS promos_cnt,
      CAST(NULL AS DOUBLE)          AS total_promo_cost
    FROM right_join
    GROUP BY d_year
  ),

  -- Aggregation of the full‑joined data
  agg_full AS (
    SELECT
      d_year,
      CAST(NULL AS BIGINT)          AS orders_cnt,
      CAST(NULL AS DOUBLE)          AS total_return_amount,
      CAST(NULL AS BIGINT)          AS rows_cnt,
      COUNT(DISTINCT p_promo_id)    AS promos_cnt,
      SUM(p_cost)                    AS total_promo_cost
    FROM full_join
    GROUP BY d_year
  ),

  -- Union of the two aggregation results (deduplication)
  union_agg AS (
    SELECT * FROM agg_right
    UNION
    SELECT * FROM agg_full
  )
SELECT
  u.d_year,
  u.orders_cnt,
  u.total_return_amount,
  u.promos_cnt,
  u.total_promo_cost,
  (SELECT COUNT(*) FROM intersect_keys) AS intersect_cnt,
  (SELECT COUNT(*) FROM union_keys)      AS union_cnt
FROM union_agg u
ORDER BY u.total_return_amount DESC NULLS LAST
LIMIT 100
