WITH promo_item AS (
  SELECT
    p.p_promo_id,
    p.p_start_date_sk,
    p.p_end_date_sk,
    p.p_cost,
    p.p_discount_active,
    i.i_brand,
    i.i_brand_id,
    i.i_category,
    i.i_current_price
  FROM promotion p
  JOIN item i ON p.p_item_sk = i.i_item_sk
  WHERE p.p_discount_active = 'Y'
    AND p.p_start_date_sk BETWEEN 2450906 AND 2451088
    AND i.i_current_price > 20
),
promo_agg AS (
  SELECT
    i_brand,
    i_brand_id,
    p_promo_id,
    MIN(p_start_date_sk) AS promo_start,
    MAX(p_end_date_sk) AS promo_end,
    SUM(p_cost) AS total_cost,
    AVG(p_cost) AS avg_cost,
    COUNT(*) AS promo_items
  FROM promo_item
  GROUP BY i_brand, i_brand_id, p_promo_id
)
SELECT
  i_brand,
  i_brand_id,
  p_promo_id,
  promo_start,
  promo_end,
  total_cost,
  avg_cost,
  promo_items,
  RANK() OVER (PARTITION BY i_brand ORDER BY total_cost DESC) AS brand_promo_rank,
  SUM(total_cost) OVER (PARTITION BY i_brand ORDER BY promo_start ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_cost_by_brand
FROM promo_agg
WHERE total_cost > 1000
ORDER BY i_brand, brand_promo_rank
LIMIT 50
