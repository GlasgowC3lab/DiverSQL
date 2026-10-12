SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_start.d_date AS event_date,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_pages,
    COUNT(DISTINCT p.p_promo_sk) AS promotions,
    SUM(p.p_cost) AS total_promo_cost,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_created,
    AVG(wp.wp_image_count) AS avg_image_count,
    MIN(d_end.d_date) AS earliest_catalog_end_date,
    MAX(d_promo_end.d_date) AS latest_promo_end_date
FROM store s
JOIN date_dim d_start
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE s.s_state = 'CA'
  AND cp.cp_type = 'Catalog'
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_start.d_date
HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) > 0
ORDER BY total_promo_cost DESC
LIMIT 100
