SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    w.web_site_id,
    w.web_name,
    w.web_city,
    w.web_state,
    d_sales.d_date AS sales_date,
    d_ship.d_date AS ship_date,
    d_store_closed.d_date AS store_closed_date,
    d_web_open.d_date AS web_open_date,
    d_web_close.d_date AS web_close_date,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_day_name
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
LEFT JOIN date_dim d_web_open
    ON w.web_open_date_sk = d_web_open.d_date_sk
LEFT JOIN date_dim d_web_close
    ON w.web_close_date_sk = d_web_close.d_date_sk
WHERE
    (s.s_closed_date_sk IS NULL OR d_store_closed.d_date > d_sales.d_date)
    AND (w.web_close_date_sk IS NULL OR d_web_close.d_date > d_sales.d_date)
    AND d_sales.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    w.web_site_id,
    w.web_name,
    w.web_city,
    w.web_state,
    d_sales.d_date,
    d_ship.d_date,
    d_store_closed.d_date,
    d_web_open.d_date,
    d_web_close.d_date,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_day_name
ORDER BY total_store_sales DESC
LIMIT 100
