SELECT
    dr_return.d_date AS return_date,
    dr_return.d_year AS return_year,
    dr_return.d_month_seq AS return_month_seq,
    dr_ship.d_date AS ship_date,
    dr_ship.d_year AS ship_year,
    dr_ship.d_month_seq AS ship_month_seq,
    dr_page_creation.d_date AS page_creation_date,
    dr_page_access.d_date AS page_access_date,
    dr_store_closed.d_date AS store_closed_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wp.wp_web_page_id,
    wp.wp_type,
    wp.wp_url,
    SUM(ws.ws_ext_sales_price)      AS total_sales_amount,
    SUM(ws.ws_net_profit)           AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount)        AS total_return_amount,
    COUNT(cr.cr_order_number)       AS total_returns,
    SUM(cr.cr_net_loss)             AS total_net_loss,
    AVG(ws.ws_quantity)             AS avg_quantity,
    MAX(ws.ws_sales_price)          AS max_sales_price,
    MIN(ws.ws_sales_price)          AS min_sales_price
FROM catalog_returns cr
JOIN date_dim dr_return
    ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = dr_return.d_date_sk
JOIN date_dim dr_ship
    ON ws.ws_ship_date_sk = dr_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dr_page_creation
    ON wp.wp_creation_date_sk = dr_page_creation.d_date_sk
JOIN date_dim dr_page_access
    ON wp.wp_access_date_sk = dr_page_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr_return.d_date_sk
JOIN date_dim dr_store_closed
    ON s.s_closed_date_sk = dr_store_closed.d_date_sk
WHERE dr_return.d_year = 2000
GROUP BY
    dr_return.d_date,
    dr_return.d_year,
    dr_return.d_month_seq,
    dr_ship.d_date,
    dr_ship.d_year,
    dr_ship.d_month_seq,
    dr_page_creation.d_date,
    dr_page_access.d_date,
    dr_store_closed.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    wp.wp_web_page_id,
    wp.wp_type,
    wp.wp_url
ORDER BY total_net_profit DESC
LIMIT 100
