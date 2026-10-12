SELECT
    d_close.d_year AS close_year,
    d_close.d_quarter_seq AS close_quarter,
    COUNT(DISTINCT cc.cc_call_center_sk) AS call_center_closed_cnt,
    AVG(date_diff('day', d_open.d_date, d_close.d_date)) AS avg_call_center_lifespan_days,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT s.s_store_sk) AS stores_closed_cnt,
    SUM(CASE WHEN s.s_state = ws.web_state THEN 1 ELSE 0 END) AS same_state_store_website_cnt,
    COUNT(DISTINCT ws.web_site_sk) AS web_sites_opened_cnt,
    AVG(ws.web_gmt_offset) AS avg_web_gmt_offset,
    AVG(date_diff('day', d_close.d_date, d_ws_close.d_date)) AS avg_website_lifespan_days
FROM date_dim d_close
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d_close.d_date_sk
LEFT JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
LEFT JOIN inventory i
    ON i.inv_date_sk = d_close.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_close.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_close.d_date_sk
LEFT JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_close.d_year BETWEEN 2005 AND 2015
GROUP BY
    d_close.d_year,
    d_close.d_quarter_seq
ORDER BY
    d_close.d_year,
    d_close.d_quarter_seq
LIMIT 100
