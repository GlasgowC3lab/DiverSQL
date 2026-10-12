SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amt,
    MIN(d_ship.d_month_seq) AS shipping_month_seq,
    MIN(date_diff('day', d_promo_start.d_date, d_promo_end.d_date)) AS promo_duration_days,
    MIN(date_diff('day', d_wp_creation.d_date, d_sold.d_date)) AS page_age_days,
    MIN(date_diff('day', d_wp_access.d_date, d_sold.d_date)) AS page_last_access_days
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_city,
    s.s_state,
    p.p_promo_name,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 10
