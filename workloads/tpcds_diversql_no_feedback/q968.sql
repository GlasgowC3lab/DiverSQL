WITH daily_warehouse AS (
   SELECT
      d.d_date,
      inv.inv_warehouse_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(inv.inv_quantity_on_hand) AS total_inventory,
      COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
   WHERE d.d_weekend = 'N'
     AND d.d_year = 2001
     AND cr.cr_return_amount > 100
     AND inv.inv_quantity_on_hand > 0
   GROUP BY d.d_date, inv.inv_warehouse_sk
)
SELECT
   d_date,
   inv_warehouse_sk,
   total_return_amount,
   total_inventory,
   return_cnt,
   CASE
      WHEN total_return_amount > 5000 THEN 'HIGH'
      WHEN total_return_amount > 2000 THEN 'MEDIUM'
      ELSE 'LOW'
   END AS return_level,
   RANK() OVER (PARTITION BY d_date ORDER BY total_return_amount DESC) AS daily_warehouse_rank
FROM daily_warehouse
ORDER BY d_date DESC, daily_warehouse_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
