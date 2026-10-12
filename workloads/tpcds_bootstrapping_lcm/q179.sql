SELECT
    cc.cc_division_name,
    w.w_city,
    d_sold.d_year,
    d_sold.d_moy AS month,
    CASE WHEN ws.ws_quantity > 5 THEN 'HIGH' ELSE 'LOW' END AS quantity_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(date_diff('day', d_cc_open.d_date, d_cc_closed.d_date)) AS avg_cc_lifespan_days,
    AVG(date_diff('day', d_store_closed.d_date, d_sold.d_date)) AS avg_store_to_sale_lag_days,
    SUM(ws.ws_ext_sales_price) / NULLIF(SUM(ws.ws_ext_discount_amt), 0) AS sales_to_discount_ratio
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2002
  AND w.w_state = 'CA'
  AND cc.cc_state = 'CA'
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_division_name,
    w.w_city,
    d_sold.d_year,
    d_sold.d_moy,
    CASE WHEN ws.ws_quantity > 5 THEN 'HIGH' ELSE 'LOW' END
ORDER BY total_sales DESC
LIMIT 100
