WITH order_agg AS (
  SELECT
    ws.ws_order_number,
    SUM(ws.ws_net_profit) AS order_profit,
    SUM(ws.ws_ext_discount_amt) AS order_discount,
    COUNT(*) AS line_items
  FROM web_sales ws
  GROUP BY ws.ws_order_number
  HAVING SUM(ws.ws_net_profit) > 0
),
order_demo AS (
  SELECT
    ws.ws_order_number,
    MIN(ws.ws_bill_cdemo_sk) AS bill_cdemo_sk,
    MIN(ws.ws_ship_cdemo_sk) AS ship_cdemo_sk
  FROM web_sales ws
  GROUP BY ws.ws_order_number
),
grouped AS (
  SELECT
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_education_status AS bill_education,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_education_status AS ship_education,
    COUNT(*) AS num_orders,
    SUM(oa.order_profit) AS total_profit,
    AVG(oa.order_discount) AS avg_discount
  FROM order_agg oa
  JOIN order_demo od ON oa.ws_order_number = od.ws_order_number
  JOIN customer_demographics cd_bill ON od.bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON od.ship_cdemo_sk = cd_ship.cd_demo_sk
  WHERE cd_bill.cd_gender = 'F'
    AND cd_ship.cd_gender = 'M'
    AND cd_bill.cd_purchase_estimate >= 1500
    AND cd_bill.cd_education_status IN ('College', '4 yr Degree')
    AND cd_ship.cd_education_status IN ('College', '4 yr Degree')
  GROUP BY
    cd_bill.cd_gender,
    cd_bill.cd_education_status,
    cd_ship.cd_gender,
    cd_ship.cd_education_status
  HAVING SUM(oa.order_profit) > 50000
)
SELECT
  bill_gender,
  bill_education,
  ship_gender,
  ship_education,
  num_orders,
  total_profit,
  avg_discount,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM grouped
ORDER BY total_profit DESC
LIMIT 100
