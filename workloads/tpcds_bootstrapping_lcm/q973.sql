SELECT
    s.s_store_id,
    s.s_store_name,
    ws_site.web_site_id,
    ws_site.web_name,
    wp.wp_type,
    d_sold.d_year,
    d_sold.d_month_seq,
    (d_sold.d_year * 100 + d_sold.d_month_seq) AS year_month_num,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(CASE WHEN d_sold.d_holiday = 'Y' THEN ws.ws_ext_sales_price ELSE 0 END) AS holiday_sales,
    SUM(CASE WHEN d_sold.d_weekend = 'Y' THEN ws.ws_ext_sales_price ELSE 0 END) AS weekend_sales,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS profit_margin,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_site_open
    ON ws_site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON ws_site.web_close_date_sk = d_site_close.d_date_sk
CROSS JOIN date_dim d_store_closed
JOIN store s
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ws_site.web_site_id,
    ws_site.web_name,
    wp.wp_type,
    d_sold.d_year,
    d_sold.d_month_seq,
    (d_sold.d_year * 100 + d_sold.d_month_seq)
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
