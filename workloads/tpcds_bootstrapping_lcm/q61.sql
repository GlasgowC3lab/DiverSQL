SELECT
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_catalog_items,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_web_items,
    SUM(cs.cs_ext_ship_cost) + SUM(ws.ws_ext_ship_cost) AS total_shipping_cost,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(wp.wp_image_count) AS total_image_count,
    COUNT(DISTINCT s.s_store_id) AS closed_stores,
    SUM(CASE WHEN d_wp_creation.d_year = d.d_year THEN 1 ELSE 0 END) AS pages_created_this_year,
    SUM(CASE WHEN d_wp_access.d_year = d.d_year THEN 1 ELSE 0 END) AS pages_accessed_this_year
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
LIMIT 100
