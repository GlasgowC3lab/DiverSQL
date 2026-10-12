WITH orders_wo_ret AS (
   SELECT cs_order_number FROM catalog_sales
   EXCEPT
   SELECT wr_order_number FROM web_returns
),
cp_sample AS (
   SELECT *
   FROM catalog_page TABLESAMPLE BERNOULLI (10)
)
SELECT
   d.d_year,
   sm.sm_carrier,
   hd.hd_buy_potential,
   cp.cp_department,
   SUM(cs.cs_net_paid) AS total_net_paid,
   SUM(cs.cs_quantity) AS total_quantity,
   COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
   AVG(cs.cs_sales_price) AS avg_sales_price,
   ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_net_paid) DESC) AS row_num
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN cp_sample cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE d.d_day_name = 'Friday'
  AND sm.sm_carrier = 'GREAT EASTERN'
  AND hd.hd_buy_potential = '1001-5000'
  AND cp.cp_department = 'Electronics'
  AND i.inv_quantity_on_hand > 100
  AND cs.cs_order_number IN (SELECT cs_order_number FROM orders_wo_ret)
GROUP BY d.d_year, sm.sm_carrier, hd.hd_buy_potential, cp.cp_department
ORDER BY total_net_paid DESC
