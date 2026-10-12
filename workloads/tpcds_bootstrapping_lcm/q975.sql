SELECT
    COALESCE(wsite.web_name, 'ALL_SITES') AS web_site,
    CASE WHEN d_sold.d_year IS NULL THEN -1 ELSE d_sold.d_year END AS sale_year,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN ws.ws_net_paid ELSE 0 END) AS weekend_sales,
    SUM(CASE WHEN d_ship.d_weekend = 'N' THEN ws.ws_net_paid ELSE 0 END) AS weekday_sales,
    AVG(date_diff('day', d_page_creation.d_date, d_page_access.d_date)) AS avg_page_age_days,
    COUNT(DISTINCT s.s_store_sk) AS store_cnt
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN date_dim d_site_open ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close ON wsite.web_close_date_sk = d_site_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
GROUP BY ROLLUP (wsite.web_name, d_sold.d_year)
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
