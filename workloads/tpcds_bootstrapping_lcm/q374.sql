SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    s.s_city,
    p.p_promo_id,
    p.p_purpose,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(d_ship.d_date) AS first_ship_date,
    MAX(d_ship.d_date) AS last_ship_date,
    MIN(d_wp_access.d_date) AS first_page_access,
    MAX(d_wp_access.d_date) AS last_page_access,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date,
    MIN(d_store_closed.d_date) AS store_closed_date
FROM
    web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE
    d_sold.d_year = 2023
    AND s.s_state = 'TX'
    AND wp.wp_type = 'content'
    AND p.p_discount_active = 'Y'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_state,
    s.s_city,
    p.p_promo_id,
    p.p_purpose,
    wp.wp_type
HAVING
    SUM(ws.ws_ext_sales_price) > 5000
ORDER BY
    total_sales DESC
LIMIT 50
