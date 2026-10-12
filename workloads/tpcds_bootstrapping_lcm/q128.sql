SELECT
    cc.cc_city,
    cc.cc_state,
    s.s_city,
    s.s_state,
    w.w_warehouse_name,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_month_seq AS ship_month,
    d_cc_open.d_year AS open_year,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_qty,
    AVG(ws.ws_sales_price) AS avg_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    cc.cc_city,
    cc.cc_state,
    s.s_city,
    s.s_state,
    w.w_warehouse_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    d_cc_open.d_year
ORDER BY total_profit DESC
LIMIT 100
