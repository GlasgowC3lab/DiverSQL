SELECT
    cd.d_year,
    cd.d_quarter_name,
    s.s_division_id,
    s.s_division_name,
    wsite.web_class,
    wsite.web_market_manager,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    AVG(date_diff('day', cd.d_date, shd.d_date)) AS avg_ship_days,
    AVG(date_diff('day', pc.d_date, pac.d_date)) AS avg_page_access_lag_days,
    AVG(date_diff('day', sod.d_date, scd2.d_date)) AS avg_site_lifespan_days,
    MAX(ws.ws_net_profit) AS max_profit_per_sale,
    MIN(ws.ws_net_profit) AS min_profit_per_sale
FROM web_sales ws
JOIN date_dim cd ON ws.ws_sold_date_sk = cd.d_date_sk
JOIN date_dim shd ON ws.ws_ship_date_sk = shd.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim pc ON wp.wp_creation_date_sk = pc.d_date_sk
JOIN date_dim pac ON wp.wp_access_date_sk = pac.d_date_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim sod ON wsite.web_open_date_sk = sod.d_date_sk
JOIN date_dim scd2 ON wsite.web_close_date_sk = scd2.d_date_sk
JOIN store s ON s.s_closed_date_sk = cd.d_date_sk
WHERE cd.d_year BETWEEN 2020 AND 2022
  AND wsite.web_state = 'CA'
  AND s.s_number_employees >= 100
GROUP BY
    cd.d_year,
    cd.d_quarter_name,
    s.s_division_id,
    s.s_division_name,
    wsite.web_class,
    wsite.web_market_manager
ORDER BY total_net_profit DESC
LIMIT 100
