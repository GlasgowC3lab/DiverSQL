SELECT
    d_sold.d_date AS sale_date,
    i.i_category,
    s.s_state,
    wp.wp_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
    MAX(d_creation.d_date) AS latest_page_creation_date,
    MIN(d_access.d_date) AS earliest_page_access_date,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS category_sales_rank
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    d_sold.d_date,
    i.i_category,
    s.s_state,
    wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
