SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    s.s_state,
    d_start.d_month_seq          AS start_month_seq,
    d_end.d_month_seq            AS end_month_seq,
    d_sold.d_year                AS sold_year,
    d_ship.d_year                AS ship_year,
    d_wp_access.d_day_name       AS wp_access_day_name,
    wp.wp_url,
    wp.wp_type,
    SUM(cs.cs_net_paid)          AS total_net_paid,
    SUM(cs.cs_net_profit)        AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM catalog_page cp
INNER JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
INNER JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
INNER JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
INNER JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
INNER JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cp.cp_type = 'PROMO'
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    s.s_state,
    d_start.d_month_seq,
    d_end.d_month_seq,
    d_sold.d_year,
    d_ship.d_year,
    d_wp_access.d_day_name,
    wp.wp_url,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
