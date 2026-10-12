SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_quantity) AS min_quantity,
    MAX(ws.ws_quantity) AS max_quantity
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year = 2002
  AND s.s_state = 'TX'
  AND cc.cc_state = 'TX'
  AND d_cc_open.d_year <= d_sold.d_year
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq
HAVING SUM(ws.ws_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 100
