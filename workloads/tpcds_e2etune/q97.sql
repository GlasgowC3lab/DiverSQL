SELECT
    sm.sm_type,
    sm.sm_carrier,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_ext_sales_price) / NULLIF(SUM(ws.ws_ext_discount_amt), 0) AS sales_to_discount_ratio
FROM
    web_sales ws
JOIN
    household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN
    household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN
    ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    hd_bill.hd_dep_count >= 2
    AND hd_bill.hd_vehicle_count >= 1
    AND hd_bill.hd_buy_potential = '1001-5000'
    AND hd_ship.hd_vehicle_count > 0
    AND sm.sm_contract = 'YvxVaJI10'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
GROUP BY
    sm.sm_type,
    sm.sm_carrier
HAVING
    SUM(ws.ws_net_profit) > 0
ORDER BY
    total_profit DESC
LIMIT 10
