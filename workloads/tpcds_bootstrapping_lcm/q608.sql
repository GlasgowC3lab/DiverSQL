SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    d_cp_start.d_date AS catalog_start_date,
    d_cp_start.d_week_seq AS start_week_seq,
    d_cp_end.d_date AS catalog_end_date,
    d_cp_end.d_year AS end_year,
    ws.web_site_id,
    ws.web_name,
    d_ws_close.d_date AS web_close_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_web_page_id,
    wp.wp_url,
    wp.wp_char_count,
    d_wp_access.d_date AS web_page_access_date
FROM catalog_page cp
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ws_close.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LIMIT 100
