SELECT
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_ship.d_month_seq,
    hd_bill.hd_income_band_sk AS bill_income_band,
    hd_ship.hd_income_band_sk AS ship_income_band,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_quantity ELSE 0 END) AS qty_gt_5,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_tax) AS total_tax,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    d_ship.d_month_seq,
    hd_bill.hd_income_band_sk,
    hd_ship.hd_income_band_sk
ORDER BY total_net_profit DESC
LIMIT 100
