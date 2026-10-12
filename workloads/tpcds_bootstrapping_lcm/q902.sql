SELECT
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_ship.d_month_seq AS ship_month_seq,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_credit_rating,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_ship.d_month_seq,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_credit_rating
ORDER BY total_profit DESC
LIMIT 100
