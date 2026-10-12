WITH
  bill_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_ext_tax,
      ca.ca_state,
      wh.w_warehouse_name
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE ws.ws_ext_tax > 15
      AND ca.ca_gmt_offset = -8.00
  ),
  ship_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      ws.ws_ext_tax,
      ca.ca_state,
      wh.w_warehouse_name
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE ws.ws_ext_tax < 30
      AND wh.w_warehouse_sq_ft > 600000
  ),
  states_dim AS (
    SELECT DISTINCT ca_state
    FROM customer_address
    WHERE ca_state IS NOT NULL
    LIMIT 5
  ),
  max_tax_one_row AS (
    SELECT MAX(ws_ext_tax) AS max_tax
    FROM web_sales
    WHERE ws_ext_tax < 100
  ),
  combined AS (
    SELECT * FROM bill_sales
    UNION ALL
    SELECT * FROM ship_sales
  )
SELECT
  c.ws_order_number,
  c.ws_ext_sales_price,
  c.ws_ext_tax,
  c.ca_state,
  c.w_warehouse_name,
  m.max_tax
FROM combined c
CROSS JOIN states_dim sd
CROSS JOIN max_tax_one_row m
WHERE c.ca_state = sd.ca_state
  AND c.ws_ext_tax > (SELECT MAX(ws_ext_tax) FROM web_sales WHERE ws_ext_tax < 100)
ORDER BY c.ws_ext_sales_price DESC
LIMIT 100
