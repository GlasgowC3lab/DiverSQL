SELECT
    d_sales.d_date AS sale_date,
    d_sales.d_day_name,
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    p.p_purpose,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_created,
    COUNT(DISTINCT CASE WHEN d_page_access.d_date = d_sales.d_date THEN wp.wp_web_page_id END) AS distinct_web_pages_accessed_same_day,
    d_store_closed.d_date AS store_closed_date,
    CASE WHEN d_store_closed.d_date = d_sales.d_date THEN TRUE ELSE FALSE END AS store_closed_on_sale_date
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
GROUP BY
    d_sales.d_date,
    d_sales.d_day_name,
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    p.p_purpose,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_store_closed.d_date
ORDER BY total_sales DESC
LIMIT 100
