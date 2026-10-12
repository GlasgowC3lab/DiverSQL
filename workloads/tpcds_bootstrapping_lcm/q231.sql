SELECT
    s.s_store_id,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    SUM(wp.wp_image_count) AS total_web_image_count,
    SUM(wp.wp_link_count) AS total_web_link_count,
    SUM(CASE WHEN wp.wp_type = 'home' THEN ss.ss_ext_sales_price ELSE 0 END) AS home_page_sales,
    SUM(CASE WHEN wp.wp_type = 'product' THEN ss.ss_ext_sales_price ELSE 0 END) AS product_page_sales
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_store_sk = s.s_store_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
GROUP BY
    s.s_store_id,
    d.d_year,
    d.d_month_seq
HAVING
    SUM(ss.ss_ext_sales_price) > 10000
ORDER BY
    total_return_amount DESC
LIMIT 100
