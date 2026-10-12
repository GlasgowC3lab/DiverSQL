SELECT
    cc.cc_company_name,
    cc.cc_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    s.s_floor_space,
    d_sold.d_date AS sale_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_weekend,
    t_sold.t_hour,
    t_sold.t_meal_time,
    d_ship.d_date AS ship_date,
    d_ship.d_weekend AS ship_weekend,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amt
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
GROUP BY
    cc.cc_company_name,
    cc.cc_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    s.s_floor_space,
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_weekend,
    t_sold.t_hour,
    t_sold.t_meal_time,
    d_ship.d_date,
    d_ship.d_weekend
ORDER BY total_sales DESC
LIMIT 100
