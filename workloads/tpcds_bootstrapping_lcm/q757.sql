SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    SUM(wp.wp_link_count) AS total_links,
    SUM(wp.wp_image_count) AS total_images,
    AVG(cc.cc_gmt_offset) AS avg_cc_gmt_offset,
    AVG(s.s_gmt_offset) AS avg_store_gmt_offset
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2020
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
