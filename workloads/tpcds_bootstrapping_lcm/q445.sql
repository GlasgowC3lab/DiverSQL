SELECT
    cc.cc_name,
    s.s_store_name,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_ship.d_day_name AS ship_day_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(hd_bill.hd_income_band_sk) AS avg_income_band_bill,
    AVG(hd_ship.hd_income_band_sk) AS avg_income_band_ship,
    SUM(ws.ws_quantity) AS total_qty
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_closed.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE d_closed.d_year = 2001
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_ship.d_day_name
ORDER BY total_sales DESC
LIMIT 100
