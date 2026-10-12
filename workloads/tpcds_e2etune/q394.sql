WITH promo_agg AS (
    SELECT
        start_date.d_fy_year AS fiscal_year,
        start_date.d_fy_quarter_seq AS fiscal_quarter,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_response_target) AS avg_response_target,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS discount_active_pct
    FROM promotion p
    JOIN date_dim start_date
        ON p.p_start_date_sk = start_date.d_date_sk
    JOIN date_dim end_date
        ON p.p_end_date_sk = end_date.d_date_sk
    WHERE start_date.d_current_year = 'Y'
      AND end_date.d_current_quarter = 'Y'
      AND p.p_channel_tv = 'Y'
    GROUP BY start_date.d_fy_year, start_date.d_fy_quarter_seq
    HAVING COUNT(*) >= 5
)
SELECT
    fiscal_year,
    fiscal_quarter,
    promo_count,
    total_promo_cost,
    avg_response_target,
    discount_active_pct,
    RANK() OVER (ORDER BY total_promo_cost DESC) AS cost_rank,
    (SELECT AVG(hd_vehicle_count) FROM household_demographics) AS avg_household_vehicle_count
FROM promo_agg
ORDER BY total_promo_cost DESC
LIMIT 20
