SELECT
    ca_bill.ca_state AS billing_state,
    wp.wp_type AS page_type,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_state_rank
FROM
    web_sales ws
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    hd_bill.hd_vehicle_count >= 2
    AND ca_bill.ca_zip LIKE '7%'
    AND ws.ws_net_paid_inc_tax > 0
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
GROUP BY
    ca_bill.ca_state,
    wp.wp_type
HAVING
    SUM(ws.ws_net_profit) > 1000
ORDER BY
    total_net_profit DESC
LIMIT 100
