SELECT
    cc.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_sold.d_year AS sale_year,
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
    CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END AS marital_status,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_quarter_name = 'Q2'
  AND cd.cd_gender = 'M'
  AND cd.cd_marital_status = 'M'
GROUP BY
    cc.cc_name,
    s.s_store_name,
    d_sold.d_year,
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END,
    CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
