WITH sales_by_state_warehouse AS (
  SELECT
    ca_bill.ca_state AS bill_state,
    w.w_city AS warehouse_city,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(CASE WHEN ws.ws_ext_list_price <> 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_list_price END) AS avg_discount_rate,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt
  FROM web_sales ws
  JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE ca_bill.ca_location_type = 'single family'
    AND ca_bill.ca_zip IN ('86192', '85709')
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    AND w.w_state = 'CA'
  GROUP BY ca_bill.ca_state, w.w_city
)
SELECT
  bill_state,
  warehouse_city,
  total_profit,
  total_sales,
  avg_discount_rate,
  total_quantity,
  order_cnt,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_by_state_warehouse
ORDER BY profit_rank
LIMIT 10
