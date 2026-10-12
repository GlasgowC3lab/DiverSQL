SELECT
    d_sold.d_year,
    d_sold.d_quarter_name,
    cc.cc_state,
    s.s_state,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    CASE
        WHEN cc.cc_state = s.s_state THEN 'SameState'
        ELSE 'DifferentState'
    END AS state_match,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_net_profit,
    (SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0)) AS profit_margin,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(*) AS line_items,
    MIN(d_sold.d_date) AS first_sale_date,
    MAX(d_sold.d_date) AS last_sale_date,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    cc.cc_state,
    s.s_state,
    ca_bill.ca_state,
    ca_ship.ca_state,
    CASE
        WHEN cc.cc_state = s.s_state THEN 'SameState'
        ELSE 'DifferentState'
    END
ORDER BY d_sold.d_year, d_sold.d_quarter_name, cc.cc_state, s.s_state
LIMIT 100
