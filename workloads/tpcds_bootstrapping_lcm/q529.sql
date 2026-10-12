SELECT
    d.d_year,
    d.d_month_seq,
    d.d_year * 100 + d.d_month_seq AS year_month_id,
    cc.cc_division,
    s.s_state,
    CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END AS promo_channel,
    wp.wp_type,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    COUNT(DISTINCT s.s_store_sk) AS num_stores,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    SUM(CASE WHEN wp.wp_autogen_flag = 'Y' THEN 1 ELSE 0 END) AS auto_generated_pages,
    SUM(p.p_cost * p.p_response_target) AS weighted_promo_cost,
    MAX(p.p_cost) AS max_promo_cost,
    MIN(p.p_cost) AS min_promo_cost,
    COUNT(*) AS total_rows,
    SUM(wp.wp_image_count) / NULLIF(COUNT(DISTINCT wp.wp_web_page_sk), 0) AS avg_images_per_page
FROM
    call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    cc.cc_division,
    s.s_state,
    CASE WHEN p.p_channel_tv = 'Y' THEN 'TV' ELSE 'Other' END,
    wp.wp_type
HAVING
    SUM(p.p_cost) > 1000
ORDER BY
    d.d_year,
    d.d_month_seq,
    cc.cc_division
