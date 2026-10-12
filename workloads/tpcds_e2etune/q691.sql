WITH agg AS (
  SELECT
    cust_bill.c_birth_year AS bill_birth_year,
    cust_ship.c_birth_year AS ship_birth_year,
    COUNT(*) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_ext_ship_cost) AS total_ship_cost
  FROM catalog_sales cs
  JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
  JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
  WHERE cs.cs_ext_ship_cost > 500
    AND cs.cs_ext_discount_amt >= 1000
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
  GROUP BY cust_bill.c_birth_year, cust_ship.c_birth_year
  HAVING COUNT(*) >= 5
)
SELECT
  bill_birth_year,
  ship_birth_year,
  order_cnt,
  total_net_profit,
  avg_discount,
  total_ship_cost,
  RANK() OVER (PARTITION BY bill_birth_year ORDER BY total_net_profit DESC) AS profit_rank_within_bill_year
FROM agg
ORDER BY bill_birth_year, profit_rank_within_bill_year
LIMIT 50
