WITH promo_item AS (
    SELECT p.p_promo_id,
           p.p_cost,
           p.p_discount_active,
           p.p_channel_email,
           p.p_channel_tv,
           i.i_item_id,
           i.i_brand,
           i.i_category,
           i.i_units,
           i.i_current_price,
           i.i_color
    FROM promotion p
    JOIN item i
      ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_email = 'Y'
)
SELECT
    pi.i_brand,
    pi.i_category,
    pi.i_units,
    COUNT(DISTINCT pi.p_promo_id) AS promo_cnt,
    SUM(pi.p_cost) AS total_promo_cost,
    AVG(pi.i_current_price) AS avg_current_price,
    ROUND(100.0 * SUM(pi.p_cost) / NULLIF(SUM(pi.i_current_price), 0), 2) AS cost_to_price_pct,
    ROW_NUMBER() OVER (ORDER BY SUM(pi.p_cost) DESC) AS brand_rank
FROM promo_item pi
WHERE pi.i_brand IS NOT NULL
GROUP BY pi.i_brand, pi.i_category, pi.i_units
HAVING SUM(pi.p_cost) > 5000
ORDER BY total_promo_cost DESC
LIMIT 20
