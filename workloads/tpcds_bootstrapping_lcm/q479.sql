SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    wsite.web_name,
    wsite.web_city,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    d_site_open.d_year AS site_open_year,
    d_site_close.d_year AS site_close_year,
    COUNT(ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MAX(d_ship.d_date) AS latest_ship_date
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_site_open
    ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON wsite.web_close_date_sk = d_site_close.d_date_sk
WHERE d_cc_closed.d_year = 2002
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_state,
    wsite.web_name,
    wsite.web_city,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    d_site_open.d_year,
    d_site_close.d_year
ORDER BY total_net_profit DESC
LIMIT 100
