SELECT 
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sales.d_date AS sales_date,
    d_sales.d_year,
    d_sales.d_month_seq,
    t.t_hour,
    t.t_minute,
    t.t_shift,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_created,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(wp.wp_link_count) AS total_links,
    CASE WHEN d_close.d_date IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_close
    ON s.s_closed_date_sk = d_close.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
GROUP BY 
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sales.d_date,
    d_sales.d_year,
    d_sales.d_month_seq,
    t.t_hour,
    t.t_minute,
    t.t_shift,
    d_close.d_date
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
