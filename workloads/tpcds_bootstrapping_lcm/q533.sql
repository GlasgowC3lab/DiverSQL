SELECT
    d_start.d_date AS event_date,
    d_start.d_year,
    d_start.d_month_seq,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    COUNT(DISTINCT s.s_store_id) AS num_stores_closed,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(p.p_response_target) AS avg_response_target,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(wp.wp_char_count) AS total_char_count,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_promo_duration_days,
    AVG(date_diff('day', d_start.d_date, d_sales.d_date)) AS avg_customer_shipto_to_sales_days,
    AVG(date_diff('day', d_start.d_date, d_access.d_date)) AS avg_access_delay_days,
    CASE
        WHEN d_start.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END AS month_parity,
    CONCAT('Q', CAST(d_start.d_quarter_seq AS VARCHAR), '-', CAST(d_start.d_year AS VARCHAR)) AS quarter_label,
    (SUM(p.p_cost) / NULLIF(SUM(s.s_floor_space), 0)) AS cost_per_sqft,
    SUM(p.p_cost * s.s_floor_space) AS weighted_cost
FROM date_dim d_start
JOIN customer c
    ON c.c_first_shipto_date_sk = d_start.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_creation_date_sk = d_start.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    d_start.d_date,
    d_start.d_year,
    d_start.d_month_seq,
    d_start.d_quarter_seq
HAVING COUNT(DISTINCT c.c_customer_id) > 1
ORDER BY d_start.d_date DESC
LIMIT 100
