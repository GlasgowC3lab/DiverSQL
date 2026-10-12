SELECT
    sold_dd.d_year AS sales_year,
    sm.sm_type AS ship_mode_type,
    s.s_state AS store_state,
    w.web_state AS website_state,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(date_diff('day', sold_dd.d_date, ship_dd.d_date)) AS avg_shipping_delay_days,
    MIN(open_dd.d_date) AS site_open_date,
    MAX(close_dd.d_date) AS site_close_date
FROM web_sales ws
JOIN date_dim AS sold_dd
    ON ws.ws_sold_date_sk = sold_dd.d_date_sk
JOIN date_dim AS ship_dd
    ON ws.ws_ship_date_sk = ship_dd.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = sold_dd.d_date_sk
JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
JOIN date_dim AS open_dd
    ON w.web_open_date_sk = open_dd.d_date_sk
JOIN date_dim AS close_dd
    ON w.web_close_date_sk = close_dd.d_date_sk
GROUP BY
    sold_dd.d_year,
    sm.sm_type,
    s.s_state,
    w.web_state
ORDER BY total_net_profit DESC
LIMIT 100
