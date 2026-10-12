SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_date AS store_closed_date,
    p.p_promo_name,
    p.p_cost,
    d.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    date_diff('day', d.d_date, d_end.d_date) AS promo_duration_days,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    d.d_date AS wp_creation_date,
    d_access.d_date AS wp_access_date,
    date_diff('day', d.d_date, d_access.d_date) AS wp_lifespan_days,
    CASE WHEN wp.wp_link_count > 0 THEN wp.wp_image_count * 1.0 / wp.wp_link_count END AS img_per_link,
    RANK() OVER (PARTITION BY s.s_store_sk ORDER BY p.p_cost DESC) AS promo_cost_rank
FROM date_dim d
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE p.p_cost > 0
ORDER BY p.p_cost DESC
LIMIT 100
