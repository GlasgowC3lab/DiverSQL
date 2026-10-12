SELECT
    d_sales.d_date,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    d_closed.d_date AS store_closed_date,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS num_web_pages_created,
    COUNT(DISTINCT CASE WHEN d_access.d_date = d_sales.d_date THEN wp.wp_web_page_id END) AS num_web_pages_accessed_same_day,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    d_sales.d_date,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    p.p_discount_active,
    d_closed.d_date,
    d_start.d_date,
    d_end.d_date
ORDER BY total_ext_sales DESC
LIMIT 100
