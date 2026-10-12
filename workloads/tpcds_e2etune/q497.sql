WITH filtered_sales AS (
  SELECT
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    ws.ws_quantity,
    sm.sm_ship_mode_id AS ship_mode_id,
    ca.ca_city AS bill_city,
    cd.cd_gender,
    cd.cd_marital_status,
    ws.ws_sold_date_sk
  FROM web_sales ws
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
    AND cd.cd_gender = 'M'
    AND cd.cd_marital_status = 'S'
    AND sm.sm_type = 'Air'
)
SELECT
  ship_mode_id,
  bill_city,
  SUM(ws_net_profit) AS total_profit,
  AVG(ws_ext_discount_amt) AS avg_discount,
  SUM(ws_quantity) AS total_quantity,
  COUNT(*) AS order_cnt,
  RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM filtered_sales
GROUP BY ship_mode_id, bill_city
HAVING SUM(ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 10
