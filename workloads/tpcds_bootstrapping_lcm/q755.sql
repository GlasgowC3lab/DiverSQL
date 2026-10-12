SELECT
    d.d_year AS return_year,
    d.d_month_seq AS return_month_seq,
    s.s_store_name,
    s.s_city,
    wp.wp_type,
    d_wp_create.d_year AS page_creation_year,
    d_wp_access.d_week_seq AS page_access_week_seq,
    COUNT(DISTINCT wr.wr_order_number) AS total_orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_items_returned,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    MAX(wp.wp_char_count) AS max_page_char_count
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_create
    ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    wp.wp_type,
    d_wp_create.d_year,
    d_wp_access.d_week_seq
ORDER BY total_return_amount DESC
LIMIT 100
