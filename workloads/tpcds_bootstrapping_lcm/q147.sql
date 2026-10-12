SELECT
    cc.cc_city,
    s.s_state,
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    hd_bill.hd_buy_potential,
    hd_ship.hd_income_band_sk,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
FROM web_sales ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_ship_date_sk = d.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
   AND cc.cc_open_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE d.d_year = 2001
  AND cc.cc_state = s.s_state
  AND hd_bill.hd_buy_potential = 'HIGH'
GROUP BY
    cc.cc_city,
    s.s_state,
    d.d_year,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    hd_bill.hd_buy_potential,
    hd_ship.hd_income_band_sk
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
