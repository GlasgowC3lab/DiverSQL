SELECT
    cp.cp_department,
    cp.cp_type,
    d_sold.d_year,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_ids,
    SUM(CASE WHEN d_sold.d_month_seq = d_ship.d_month_seq AND d_sold.d_year = d_ship.d_year THEN cs.cs_ext_sales_price ELSE 0 END) AS sales_same_month,
    SUM(CASE WHEN d_sold.d_quarter_seq = d_ship.d_quarter_seq AND d_sold.d_year = d_ship.d_year THEN cs.cs_ext_sales_price ELSE 0 END) AS sales_same_quarter,
    SUM(CASE WHEN d_page_start.d_year = d_sold.d_year THEN cs.cs_net_paid ELSE 0 END) AS net_paid_start_year_match,
    COUNT(CASE WHEN wp.wp_autogen_flag = 'Y' THEN 1 END) AS auto_generated_pages,
    MIN(d_page_end.d_date) AS min_page_end_date,
    MAX(d_page_end.d_date) AS max_page_end_date,
    COUNT(DISTINCT d_wp_access.d_week_seq) AS distinct_access_weeks
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_page_start
    ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
    ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_page_start.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2000 AND 2005
    AND s.s_state = 'CA'
    AND cp.cp_type = 'PRODUCT'
    AND wp.wp_type = 'HOME'
GROUP BY
    cp.cp_department,
    cp.cp_type,
    d_sold.d_year,
    s.s_state
HAVING
    SUM(cs.cs_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
