SELECT
    s.s_store_id,
    s.s_city,
    d_cs_sold.d_year AS sales_year,
    d_cs_sold.d_month_seq AS sales_month,
    CASE WHEN d_cs_ship.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS ship_half_year,
    wp.wp_type,
    d_wp_create.d_year AS page_creation_year,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(cs.cs_net_profit) AS catalog_profit_total,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(ws.ws_net_profit) AS web_profit_total,
    SUM(cs.cs_ext_sales_price) - SUM(ws.ws_ext_sales_price) AS sales_diff,
    AVG(CASE WHEN cs.cs_quantity > 0 THEN cs.cs_ext_sales_price / cs.cs_quantity END) AS avg_catalog_price_per_qty,
    AVG(CASE WHEN ws.ws_quantity > 0 THEN ws.ws_ext_sales_price / ws.ws_quantity END) AS avg_web_price_per_qty,
    SUM(cs.cs_coupon_amt) AS total_catalog_coupon,
    SUM(ws.ws_coupon_amt) AS total_web_coupon,
    SUM(CASE WHEN d_wp_access.d_dow IN (6,7) THEN ws.ws_ext_sales_price ELSE 0 END) AS weekend_web_sales,
    SUM(CASE WHEN cs.cs_net_profit > ws.ws_net_profit THEN 1 ELSE 0 END) AS catalog_higher_profit_cnt,
    SUM(CASE WHEN d_ws_ship.d_month_seq = 12 THEN 1 ELSE 0 END) AS web_dec_ship_cnt
FROM catalog_sales cs
JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cs_sold.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    d_cs_sold.d_year,
    d_cs_sold.d_month_seq,
    CASE WHEN d_cs_ship.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    wp.wp_type,
    d_wp_create.d_year
HAVING
    SUM(cs.cs_ext_sales_price) > 0
ORDER BY
    s.s_store_id,
    sales_year,
    wp.wp_type
