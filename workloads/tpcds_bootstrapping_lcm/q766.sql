SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_state,
    s.s_city,
    s.s_store_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    MAX(d_closed.d_date) AS store_closed_date,
    MAX(d_wp_access.d_date) AS latest_page_access_date
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_sales.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sales.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY d_sales.d_year, d_sales.d_month_seq, s.s_state, s.s_city, s.s_store_name
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
