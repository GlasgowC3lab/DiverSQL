SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_tax_percentage,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    s.s_store_sk,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    d_cc_closed.d_year AS sold_year,
    d_cc_closed.d_month_seq AS sold_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    t.t_hour,
    t.t_minute,
    t.t_meal_time
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
ORDER BY ws.ws_net_profit DESC
LIMIT 100
