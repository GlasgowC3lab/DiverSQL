SELECT
    sold.d_year AS sold_year,
    sold.d_month_seq AS sold_month,
    ship.d_year AS ship_year,
    ship.d_month_seq AS ship_month,
    store.s_state,
    store.s_market_manager,
    wp.wp_url,
    creation.d_year AS creation_year,
    access.d_year AS access_year,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_paid_inc_tax) AS total_paid_inc_tax,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_quantity) AS avg_quantity
FROM web_sales ws
JOIN date_dim AS sold ON ws.ws_sold_date_sk = sold.d_date_sk
JOIN date_dim AS ship ON ws.ws_ship_date_sk = ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim AS creation ON wp.wp_creation_date_sk = creation.d_date_sk
JOIN date_dim AS access ON wp.wp_access_date_sk = access.d_date_sk
JOIN store ON store.s_closed_date_sk = sold.d_date_sk
WHERE sold.d_year = 2020
GROUP BY
    sold.d_year,
    sold.d_month_seq,
    ship.d_year,
    ship.d_month_seq,
    store.s_state,
    store.s_market_manager,
    wp.wp_url,
    creation.d_year,
    access.d_year
ORDER BY total_sales DESC
LIMIT 100
