WITH filtered_inventory AS (
   SELECT inv_item_sk,
          inv_quantity_on_hand,
          inv_date_sk,
          inv_warehouse_sk
   FROM inventory
   WHERE inv_date_sk IN (2450927, 2450934, 2451053)
),
joined AS (
   SELECT ib.ib_income_band_sk,
          ib.ib_lower_bound,
          ib.ib_upper_bound,
          inv.inv_warehouse_sk,
          COUNT(*) AS item_count,
          SUM(inv.inv_quantity_on_hand) AS total_qty,
          AVG(inv.inv_quantity_on_hand) AS avg_qty
   FROM filtered_inventory inv
   JOIN income_band ib
     ON inv.inv_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
   WHERE ib.ib_income_band_sk IN (1, 2, 3, 4, 5)
   GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, inv.inv_warehouse_sk
   HAVING SUM(inv.inv_quantity_on_hand) > 1000
)
SELECT *,
       RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_qty DESC) AS warehouse_qty_rank
FROM joined
ORDER BY ib_income_band_sk, total_qty DESC
LIMIT 100
