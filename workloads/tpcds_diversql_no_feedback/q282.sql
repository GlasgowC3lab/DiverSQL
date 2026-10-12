WITH filtered_sales AS (
    SELECT *
    FROM web_sales
    WHERE ws_ext_wholesale_cost > 1000
      AND ws_ext_wholesale_cost < 2500
      AND ws_net_paid >= 1500
      AND ws_ship_customer_sk IN (6685171, 9221248)
      AND ws_quantity >= 2
      AND ws_ext_discount_amt > 0
),
addr_filtered AS (
    SELECT *
    FROM customer_address
    WHERE ca_street_name = 'Pine Oak'
      AND ca_suite_number = 'Suite 200'
      AND ca_street_number = '59'
)
SELECT
    ca.ca_state,
    ca.ca_city,
    ca.ca_suite_number,
    COUNT(*) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_net_profit) AS min_profit,
    MAX(ws.ws_net_profit) AS max_profit
FROM filtered_sales ws
JOIN addr_filtered ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ws.ws_order_number NOT IN (
    SELECT ws2.ws_order_number
    FROM web_sales ws2
    WHERE ws2.ws_quantity = 0
)
GROUP BY ca.ca_state, ca.ca_city, ca.ca_suite_number
ORDER BY total_net_paid DESC
LIMIT 100
