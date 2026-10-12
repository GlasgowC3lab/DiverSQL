SELECT
    cp.cp_department,
    d_sales.d_year AS sales_year,
    d_ship.d_week_seq AS ship_week_seq,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    SUM(CASE WHEN cs.cs_quantity > 1 THEN cs.cs_quantity ELSE 0 END) AS total_multi_quantity,
    MAX(cs.cs_sales_price) AS max_sales_price,
    SUM(wp.wp_image_count) AS total_image_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(CASE WHEN d_page_start.d_month_seq = d_page_end.d_month_seq THEN 1 ELSE 0 END) AS same_month_page_count,
    COUNT(*) AS total_rows
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sales
    ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN store s
    ON TRUE
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON TRUE
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    cs.cs_net_paid > 0
    AND cp.cp_type = 'C'
    AND s.s_market_desc LIKE '%Online%'
    AND d_sales.d_current_year = '2022'
GROUP BY
    CUBE (cp.cp_department, d_sales.d_year, s.s_state),
    d_ship.d_week_seq
