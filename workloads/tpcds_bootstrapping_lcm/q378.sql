SELECT
    s.s_store_id,
    s.s_city,
    p.p_promo_name,
    date_format(d_store_closed.d_date, '%Y-%m') AS store_closed_month,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(wp.wp_char_count) AS avg_page_chars,
    SUM(CASE WHEN wp.wp_type = 'Landing' THEN 1 ELSE 0 END) AS landing_page_visits,
    MAX(d_wp_access.d_date) AS latest_access_date
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_customer_shipto
    ON c.c_first_shipto_date_sk = d_customer_shipto.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    p.p_promo_name,
    date_format(d_store_closed.d_date, '%Y-%m')
HAVING
    SUM(p.p_cost) > 0
ORDER BY total_promo_cost DESC
LIMIT 100
