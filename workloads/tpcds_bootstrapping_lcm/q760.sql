SELECT
    d.d_year,
    d.d_quarter_seq,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'FullPrice' END AS discount_flag,
    CASE
        WHEN date_diff('day', d.d_date, d_end.d_date) <= 30 THEN '0-30'
        WHEN date_diff('day', d.d_date, d_end.d_date) <= 90 THEN '31-90'
        ELSE '90+'
    END AS promo_duration_bucket,
    CASE WHEN (d.d_month_seq % 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT s.s_store_sk) AS distinct_store_cnt,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_page_cnt,
    SUM(CASE WHEN wp.wp_type = 'article' THEN 1 ELSE 0 END) AS article_page_cnt,
    AVG(date_diff('day', d.d_date, d_access.d_date)) AS avg_days_to_access,
    SUM(i.inv_quantity_on_hand) / NULLIF(COUNT(DISTINCT s.s_store_sk), 0) AS avg_inventory_per_store
FROM date_dim d
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
LEFT JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
LEFT JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2025
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'FullPrice' END,
    CASE
        WHEN date_diff('day', d.d_date, d_end.d_date) <= 30 THEN '0-30'
        WHEN date_diff('day', d.d_date, d_end.d_date) <= 90 THEN '31-90'
        ELSE '90+'
    END,
    CASE WHEN (d.d_month_seq % 2) = 0 THEN 'EvenMonth' ELSE 'OddMonth' END
ORDER BY total_inventory DESC
LIMIT 100
