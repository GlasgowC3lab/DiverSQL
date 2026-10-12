SELECT
    cp.cp_catalog_number,
    d_sold.d_year AS sale_year,
    s.s_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(*) AS sales_count,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
    MAX(date_diff('day', d_start.d_date, d_end.d_date)) AS catalog_lifespan_days,
    MAX(CASE WHEN wp.wp_type = 'home' THEN wp.wp_url END) AS home_page_url,
    MAX(d_access.d_year) AS max_access_year
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year BETWEEN 2001 AND 2005
  AND s.s_state = 'TX'
  AND wp.wp_type = 'content'
GROUP BY cp.cp_catalog_number, d_sold.d_year, s.s_state
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
