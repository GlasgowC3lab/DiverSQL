WITH band_inventory AS (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           SUM(inv.inv_quantity_on_hand) AS total_quantity,
           COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_cnt,
           AVG(inv.inv_quantity_on_hand) AS avg_quantity
    FROM inventory inv
    JOIN income_band ib
      ON inv.inv_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE inv.inv_quantity_on_hand > 0
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT bi.ib_income_band_sk,
       bi.ib_lower_bound,
       bi.ib_upper_bound,
       bi.total_quantity,
       bi.warehouse_cnt,
       bi.avg_quantity,
       RANK() OVER (ORDER BY bi.total_quantity DESC) AS quantity_rank
FROM band_inventory bi
ORDER BY quantity_rank
LIMIT 5
