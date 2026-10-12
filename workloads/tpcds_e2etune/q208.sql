SELECT
    CASE
        WHEN p.p_channel_tv = 'Y' THEN 'TV'
        WHEN p.p_channel_email = 'Y' THEN 'Email'
        WHEN p.p_channel_radio = 'Y' THEN 'Radio'
        WHEN p.p_channel_catalog = 'Y' THEN 'Catalog'
        ELSE 'Other'
    END AS promo_channel,
    s.d_fy_quarter_seq AS fiscal_quarter,
    date_diff('day', s.d_date, e.d_date) + 1 AS promo_days,
    AVG(i.inv_quantity_on_hand) AS avg_qty_on_hand,
    SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT p.p_promo_sk) AS promo_count
FROM promotion p
JOIN date_dim s ON p.p_start_date_sk = s.d_date_sk
JOIN date_dim e ON p.p_end_date_sk = e.d_date_sk
JOIN inventory i ON i.inv_date_sk BETWEEN s.d_date_sk AND e.d_date_sk
JOIN date_dim di ON i.inv_date_sk = di.d_date_sk
WHERE s.d_fy_year = 1902
  AND p.p_discount_active = 'Y'
GROUP BY 1, 2, 3
ORDER BY total_qty_on_hand DESC
LIMIT 100
