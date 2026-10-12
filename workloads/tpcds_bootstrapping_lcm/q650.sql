SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    p.p_promo_id,
    p.p_promo_name,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date,
    d_store_closed.d_date AS store_closed_date,
    d_ws_open.d_date AS web_open_date,
    d_ws_close.d_date AS web_close_date,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    greatest(d_cc_open.d_date, d_ws_open.d_date, d_promo_start.d_date) AS overlap_start_date,
    least(d_cc_closed.d_date, d_ws_close.d_date, d_promo_end.d_date) AS overlap_end_date,
    CASE
        WHEN least(d_cc_closed.d_date, d_ws_close.d_date, d_promo_end.d_date) >= greatest(d_cc_open.d_date, d_ws_open.d_date, d_promo_start.d_date)
        THEN date_diff('day', greatest(d_cc_open.d_date, d_ws_open.d_date, d_promo_start.d_date), least(d_cc_closed.d_date, d_ws_close.d_date, d_promo_end.d_date)) + 1
        ELSE 0
    END AS overlap_days,
    p.p_cost * CASE
        WHEN least(d_cc_closed.d_date, d_ws_close.d_date, d_promo_end.d_date) >= greatest(d_cc_open.d_date, d_ws_open.d_date, d_promo_start.d_date)
        THEN date_diff('day', greatest(d_cc_open.d_date, d_ws_open.d_date, d_promo_start.d_date), least(d_cc_closed.d_date, d_ws_close.d_date, d_promo_end.d_date)) + 1
        ELSE 0
    END AS overlap_cost_estimate
FROM call_center cc
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN web_site ws
JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
CROSS JOIN promotion p
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE greatest(d_cc_open.d_date, d_ws_open.d_date, d_promo_start.d_date) <= least(d_cc_closed.d_date, d_ws_close.d_date, d_promo_end.d_date)
ORDER BY overlap_cost_estimate DESC
LIMIT 100
