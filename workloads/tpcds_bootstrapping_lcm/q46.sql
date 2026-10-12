SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    ws.web_site_sk,
    ws.web_name,
    ws.web_city,
    p.p_promo_sk,
    p.p_promo_name,
    p.p_cost,
    d_closed.d_date AS event_date,
    d_open.d_date AS cc_open_date,
    d_ws_close.d_date AS web_close_date,
    d_promo_end.d_date AS promo_end_date,
    date_diff('day', d_open.d_date, d_closed.d_date) AS cc_operating_days,
    date_diff('day', d_closed.d_date, d_promo_end.d_date) AS days_until_promo_end,
    date_diff('day', d_ws_open.d_date, d_ws_close.d_date) AS web_site_active_days
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_closed.d_date_sk
JOIN date_dim d_ws_open
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_closed.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_closed.d_year = 2023
ORDER BY p.p_cost DESC
LIMIT 100
