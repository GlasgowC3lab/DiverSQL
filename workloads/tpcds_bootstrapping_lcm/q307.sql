SELECT
    d_sold.d_year AS sold_year,
    (d_sold.d_month_seq % 2) AS month_parity,
    s.s_division_name AS division_name,
    w.web_market_manager AS market_manager,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_quantity) AS avg_quantity,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_days,
    SUM(CASE WHEN w.web_state = 'CA' THEN ws.ws_ext_sales_price ELSE 0 END) AS ca_sales,
    SUM(CASE WHEN d_sold.d_dow IN (1,7) THEN ws.ws_ext_sales_price ELSE 0 END) AS weekend_sales,
    SUM(ws.ws_ext_sales_price * ws.ws_quantity) AS sales_quantity_product
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN date_dim d_open ON w.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON w.web_close_date_sk = d_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
  AND ws.ws_quantity > 0
GROUP BY
    d_sold.d_year,
    (d_sold.d_month_seq % 2),
    s.s_division_name,
    w.web_market_manager
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
