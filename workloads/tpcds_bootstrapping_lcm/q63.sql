SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_moy AS sold_month,
    d_ship.d_week_seq AS ship_week_seq,
    w.w_state AS warehouse_state,
    s.s_state AS store_state,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_category,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_coupon_amt) AS total_coupon_amount,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    MIN(d_page_creation.d_date) AS earliest_page_creation,
    MAX(d_page_access.d_date) AS latest_page_access,
    SUM(ws.ws_wholesale_cost * ws.ws_quantity) AS total_wholesale_cost_estimate
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_store ON ws.ws_sold_date_sk = d_store.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_store.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_moy,
    d_ship.d_week_seq,
    w.w_state,
    s.s_state,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Positive' ELSE 'NonPositive' END
HAVING COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY sold_year DESC, sold_month, total_net_paid DESC
LIMIT 100
