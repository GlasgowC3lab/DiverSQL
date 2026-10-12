WITH promo_item AS (
  SELECT
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT p.p_promo_sk) AS promo_count,
    AVG(p.p_response_target) AS avg_response_target
  FROM promotion p
  JOIN item i ON p.p_item_sk = i.i_item_sk
  WHERE p.p_start_date_sk >= 20200101
    AND p.p_end_date_sk <= 20211231
    AND i.i_category IN ('Electronics', 'Furniture', 'Clothing')
  GROUP BY i.i_category, i.i_brand, p.p_promo_name
  HAVING SUM(p.p_cost) > 5000
)
SELECT
  pi.i_category,
  pi.i_brand,
  pi.p_promo_name,
  pi.total_promo_cost,
  pi.promo_count,
  pi.avg_response_target,
  RANK() OVER (ORDER BY pi.total_promo_cost DESC) AS cost_rank,
  approx_percentile(pi.total_promo_cost, 0.5) OVER () AS overall_median_cost
FROM promo_item pi
ORDER BY pi.total_promo_cost DESC
LIMIT 100
