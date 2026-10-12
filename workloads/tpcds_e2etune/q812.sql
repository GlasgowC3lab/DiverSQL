SELECT
    ca_bill.ca_city AS bill_city,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_city AS ship_city,
    ca_ship.ca_state AS ship_state,
    t.t_shift,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_wholesale_cost) AS total_cost,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS order_cnt
FROM web_sales ws
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE
    t.t_shift = 'morning'
    AND hd_bill.hd_vehicle_count >= 2
    AND hd_ship.hd_vehicle_count >= 1
    AND ca_bill.ca_gmt_offset = -6.00
    AND ca_ship.ca_gmt_offset = -6.00
    AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY
    ca_bill.ca_city,
    ca_bill.ca_state,
    ca_ship.ca_city,
    ca_ship.ca_state,
    t.t_shift
HAVING
    SUM(ws.ws_net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 20
