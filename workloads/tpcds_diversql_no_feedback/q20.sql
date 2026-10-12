WITH filtered_sales AS (
   SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cs.cs_ext_sales_price,
      cs.cs_ext_discount_amt,
      cs.cs_sold_time_sk,
      c.c_customer_sk,
      c.c_birth_country,
      c.c_email_address,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_warehouse_sq_ft,
      w.w_city
   FROM catalog_sales cs
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE w.w_warehouse_sq_ft > 700000
     AND c.c_birth_country = 'UKRAINE'
     AND cs.cs_ext_discount_amt > 500
),
excluded_orders AS (
   SELECT cs_order_number
   FROM catalog_sales
   WHERE cs_ext_discount_amt > 10000
),
order_exceptions AS (
   SELECT cs_order_number
   FROM catalog_sales
   WHERE cs_ext_discount_amt < 100
   EXCEPT
   SELECT cs_order_number
   FROM catalog_sales
   WHERE cs_ext_discount_amt = 0
)
SELECT
   fs.cs_order_number,
   fs.w_warehouse_name,
   fs.w_city,
   fs.c_birth_country,
   fs.cs_net_profit,
   (
      SELECT SUM(cs2.cs_ext_sales_price)
      FROM catalog_sales cs2
      WHERE cs2.cs_bill_customer_sk = fs.c_customer_sk
   ) AS total_customer_sales,
   RANK() OVER (PARTITION BY fs.w_warehouse_name ORDER BY fs.cs_net_profit DESC) AS profit_rank,
   AVG(fs.cs_net_profit) OVER (PARTITION BY fs.w_warehouse_name ORDER BY fs.cs_net_profit ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS profit_moving_avg
FROM filtered_sales fs
WHERE fs.cs_order_number NOT IN (SELECT cs_order_number FROM excluded_orders)
  AND fs.cs_order_number NOT IN (SELECT cs_order_number FROM order_exceptions)
ORDER BY fs.w_warehouse_name, profit_rank
LIMIT 100
