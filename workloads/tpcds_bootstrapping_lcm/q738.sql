SELECT
    s.s_store_id,
    s.s_city,
    d_store.d_year AS closure_year,
    d_store.d_month_seq AS closure_month_seq,
    d_access.d_year AS access_year,
    d_access.d_month_seq AS access_month_seq,
    COUNT(wp.wp_web_page_sk) AS total_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(CASE WHEN wp.wp_type = 'product' THEN wp.wp_image_count ELSE 0 END) AS product_image_sum,
    SUM(CASE WHEN wp.wp_type = 'category' THEN wp.wp_image_count ELSE 0 END) AS category_image_sum,
    AVG(wp.wp_char_count) AS avg_char_count,
    MAX(wp.wp_image_count) AS max_image_count,
    MIN(wp.wp_image_count) AS min_image_count,
    SUM(wp.wp_image_count) / NULLIF(COUNT(wp.wp_web_page_sk), 0) AS avg_images_per_page,
    COUNT(DISTINCT wp.wp_url) AS distinct_url_count,
    COUNT(*) FILTER (WHERE d_access.d_weekend = 'Y') AS weekend_page_accesses,
    DATE_DIFF('day', d_store.d_date, d_access.d_date) AS days_between_closure_and_access,
    CASE
        WHEN DATE_DIFF('day', d_store.d_date, d_access.d_date) > 365 THEN 'OverYear'
        ELSE 'WithinYear'
    END AS access_gap_category
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_store.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE
    s.s_market_id IS NOT NULL
    AND wp.wp_autogen_flag = 'N'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_store.d_year,
    d_store.d_month_seq,
    d_access.d_year,
    d_access.d_month_seq,
    d_store.d_date,
    d_access.d_date
HAVING
    COUNT(wp.wp_web_page_sk) > 5
ORDER BY
    total_pages DESC
LIMIT 100
