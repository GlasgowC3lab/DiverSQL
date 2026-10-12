SELECT
    sm.sm_type AS ship_mode_type,
    cd_bill.cd_marital_status AS marital_status,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450870 AND 2450900
  AND cs.cs_net_paid_inc_ship_tax > 5000
  AND cd_bill.cd_marital_status = 'M'
  AND cd_bill.cd_credit_rating = 'A'
  AND cd_ship.cd_gender = 'F'
GROUP BY sm.sm_type, cd_bill.cd_marital_status
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 5
