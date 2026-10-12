WITH ws_filtered AS (
    SELECT ws.*,
           cd_bill.cd_credit_rating AS bill_credit_rating,
           cd_ship.cd_marital_status AS ship_marital_status,
           cd_ship.cd_education_status AS ship_education_status,
           sm.sm_type AS ship_mode_type,
           w.w_state AS warehouse_state,
           w.w_city AS warehouse_city
    FROM web_sales ws
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd_bill.cd_credit_rating = 'Good'
      AND cd_ship.cd_marital_status = 'M'
      AND cd_ship.cd_education_status = 'College'
      AND ws.ws_sold_date_sk BETWEEN 2459000 AND 2459500
)
SELECT ship_mode_type,
       warehouse_state,
       SUM(ws_ext_sales_price) AS total_sales,
       SUM(ws_ext_discount_amt) AS total_discount,
       SUM(ws_quantity) AS total_quantity,
       SUM(ws_net_profit) AS total_net_profit,
       AVG(ws_net_profit) AS avg_net_profit_per_order,
       RANK() OVER (PARTITION BY ship_mode_type ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM ws_filtered
GROUP BY ship_mode_type, warehouse_state
HAVING SUM(ws_quantity) > 1000
ORDER BY ship_mode_type, profit_rank
LIMIT 50
