SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_start.d_year AS start_year,
    d_end.d_year AS end_year,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    wp.wp_url,
    d_access.d_month_seq AS access_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(d_sold.d_date) AS first_sold_date,
    MAX(d_ship.d_date) AS last_ship_date
FROM catalog_page cp
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN web_sales ws
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
WHERE cp.cp_type = 'Catalog'
  AND s.s_state = 'CA'
  AND wp.wp_type = 'Home'
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_start.d_year,
    d_end.d_year,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    wp.wp_url,
    d_access.d_month_seq
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
