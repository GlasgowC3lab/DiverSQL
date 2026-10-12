WITH promo_max_cost AS (
    SELECT MAX(p_cost) AS max_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
)
SELECT
    d.d_date,
    d.d_year,
    p.p_promo_name,
    p.p_cost,
    w.wp_url,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    RANK() OVER (PARTITION BY d.d_year ORDER BY p.p_cost DESC) AS cost_rank_year,
    SUM(p.p_cost) OVER (
        PARTITION BY d.d_year
        ORDER BY d.d_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_3_days
FROM date_dim d
FULL OUTER JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
LEFT JOIN web_page w
    ON w.wp_creation_date_sk = d.d_date_sk
WHERE
    d.d_year = 2000
    AND p.p_channel_catalog = 'N'
    AND w.wp_type = 'article'
    AND p.p_cost > (SELECT max_cost FROM promo_max_cost)
ORDER BY d.d_year DESC, cost_rank_year ASC, d.d_date
LIMIT 100
