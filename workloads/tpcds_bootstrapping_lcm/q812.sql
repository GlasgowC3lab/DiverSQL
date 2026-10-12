SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_date AS store_closed_date,
    d_store.d_year AS store_closed_year,
    d_store.d_month_seq AS store_closed_month_seq,
    d_store.d_day_name AS store_closed_day_name,
    d_site_open.d_date AS site_open_date,
    d_site_open.d_day_name AS site_open_day_name,
    d_site_close.d_date AS site_close_date,
    d_site_close.d_day_name AS site_close_day_name,
    ws.web_name,
    ws.web_state,
    ws.web_market_manager,
    d_page_create.d_date AS page_creation_date,
    d_page_create.d_day_name AS page_creation_day_name,
    d_page_access.d_date AS page_access_date,
    d_page_access.d_day_name AS page_access_day_name,
    wp.wp_url,
    wp.wp_type,
    wp.wp_char_count,
    wp.wp_image_count,
    wp.wp_link_count,
    date_diff('day', d_page_create.d_date, d_page_access.d_date) AS days_between_creation_and_access,
    CASE
        WHEN date_diff('day', d_page_create.d_date, d_page_access.d_date) > 0 THEN 'Accessed after creation'
        WHEN date_diff('day', d_page_create.d_date, d_page_access.d_date) = 0 THEN 'Same day'
        ELSE 'Accessed before creation'
    END AS access_timing,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY wp.wp_char_count DESC) AS page_rank
FROM store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_store.d_date_sk
JOIN date_dim d_site_open ON ws.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close ON ws.web_close_date_sk = d_site_close.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_store.d_date_sk
JOIN date_dim d_page_create ON wp.wp_creation_date_sk = d_page_create.d_date_sk
JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
WHERE s.s_state = 'CA'
  AND ws.web_state = 'CA'
ORDER BY page_rank
LIMIT 100
