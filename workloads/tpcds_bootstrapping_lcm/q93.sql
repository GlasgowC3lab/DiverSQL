SELECT
    row_number() OVER (ORDER BY date_diff('day', d_open.d_date, d_closed.d_date) DESC) AS rank,
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_employees,
    cc.cc_sq_ft,
    d_closed.d_date AS cc_closed_date,
    d_open.d_date AS cc_open_date,
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    d_cp_start.d_date AS cp_start_date,
    d_closed.d_date AS cp_end_date,
    s.s_store_id,
    s.s_store_name,
    s.s_floor_space,
    d_closed.d_date AS store_closed_date,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    d_open.d_date AS web_open_date,
    d_ws_close.d_date AS web_close_date,
    date_diff('day', d_open.d_date, d_closed.d_date) AS cc_lifespan_days,
    date_diff('day', d_cp_start.d_date, d_closed.d_date) AS catalog_page_duration_days,
    date_diff('day', d_open.d_date, d_ws_close.d_date) AS web_lifespan_days
FROM call_center cc
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d_closed.d_date_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
ORDER BY cc_lifespan_days DESC
LIMIT 100
