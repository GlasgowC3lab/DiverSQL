SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_quarter.d_quarter_name,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(COALESCE(wp.wp_image_count, 0)) AS total_images_on_promo_start,
    MAX(d_closed.d_date) AS store_closed_date,
    MIN(d_start.d_date) AS promo_start_date,
    MAX(d_end.d_date) AS promo_end_date
FROM store_sales ss
JOIN date_dim d_quarter
    ON ss.ss_sold_date_sk = d_quarter.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
WHERE d_quarter.d_year = 2022
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_quarter.d_quarter_name,
    p.p_promo_name
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
