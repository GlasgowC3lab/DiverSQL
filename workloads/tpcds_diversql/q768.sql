WITH bill_demo AS (
    SELECT ws.ws_order_number,
           ws.ws_net_paid_inc_ship_tax,
           ws.ws_coupon_amt,
           cd.cd_education_status,
           ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
      AND ws.ws_coupon_amt > 500
),
ship_demo AS (
    SELECT ws.ws_order_number,
           ws.ws_net_paid_inc_ship_tax,
           ws.ws_coupon_amt,
           cd.cd_education_status,
           ws.ws_ship_customer_sk
    FROM web_sales ws
    JOIN customer_demographics cd
      ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_employed_count >= 2
      AND ws.ws_coupon_amt > 300
),
common_orders AS (
    SELECT ws_order_number FROM bill_demo
    INTERSECT
    SELECT ws_order_number FROM ship_demo
),
bill_not_ship AS (
    SELECT ws_order_number FROM bill_demo
    EXCEPT
    SELECT ws_order_number FROM ship_demo
)
SELECT order_number,
       net_paid_inc_ship_tax,
       education_status,
       coupon_amt
FROM (
    SELECT b.ws_order_number AS order_number,
           b.ws_net_paid_inc_ship_tax AS net_paid_inc_ship_tax,
           b.cd_education_status AS education_status,
           b.ws_coupon_amt AS coupon_amt
    FROM bill_demo b
    WHERE b.ws_order_number IN (SELECT ws_order_number FROM common_orders)
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = b.ws_bill_customer_sk
            AND ws2.ws_coupon_amt > 200
      )
      AND b.ws_net_paid_inc_ship_tax > (
          SELECT avg(ws_net_paid_inc_ship_tax)
          FROM web_sales
          WHERE ws_ship_cdemo_sk = 41329
      )
    UNION
    SELECT s.ws_order_number AS order_number,
           s.ws_net_paid_inc_ship_tax AS net_paid_inc_ship_tax,
           s.cd_education_status AS education_status,
           s.ws_coupon_amt AS coupon_amt
    FROM ship_demo s
    WHERE s.ws_order_number IN (SELECT ws_order_number FROM bill_not_ship)
      AND EXISTS (
          SELECT 1
          FROM web_sales ws3
          WHERE ws3.ws_ship_customer_sk = s.ws_ship_customer_sk
            AND ws3.ws_coupon_amt > 200
      )
      AND s.ws_net_paid_inc_ship_tax > (
          SELECT avg(ws_net_paid_inc_ship_tax)
          FROM web_sales
          WHERE ws_ship_cdemo_sk = 41329
      )
) AS unioned
ORDER BY net_paid_inc_ship_tax DESC
LIMIT 100
