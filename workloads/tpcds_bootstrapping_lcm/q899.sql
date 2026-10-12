SELECT
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month,
    cc.cc_state AS call_center_state,
    s.s_state AS store_state,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    SUM(CASE WHEN ws.ws_coupon_amt > 0 THEN ws.ws_coupon_amt ELSE 0 END) AS total_coupon_amount,
    SUM(ws.ws_quantity) AS total_quantity
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
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    cc.cc_state,
    s.s_state
ORDER BY total_net_paid DESC
LIMIT 100
