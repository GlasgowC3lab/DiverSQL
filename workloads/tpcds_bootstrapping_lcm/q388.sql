SELECT
    d_sold.d_year,
    CASE WHEN d_sold.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    t.t_shift,
    s.s_state,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_wholesale_cost) AS gross_margin,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_quantity) AS max_quantity
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
WHERE d_sold.d_year = 2001
  AND t.t_shift IN ('Morning', 'Afternoon')
GROUP BY
    d_sold.d_year,
    CASE WHEN d_sold.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    t.t_shift,
    s.s_state,
    wp.wp_type
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
