SELECT
  ib_income_band_sk,
  inv_warehouse_sk,
  total_qty,
  RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_qty DESC) AS warehouse_rank
FROM (
  SELECT
    ib.ib_income_band_sk,
    i.inv_warehouse_sk,
    COUNT(*) AS cnt_records,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    AVG(i.inv_quantity_on_hand) AS avg_qty,
    MIN(i.inv_quantity_on_hand) AS min_qty,
    MAX(i.inv_quantity_on_hand) AS max_qty
  FROM inventory i
  JOIN income_band ib
    ON i.inv_warehouse_sk = ib.ib_income_band_sk
  WHERE i.inv_date_sk BETWEEN 2450815 AND 2451053
    AND i.inv_quantity_on_hand > 200
  GROUP BY ib.ib_income_band_sk, i.inv_warehouse_sk
  HAVING SUM(i.inv_quantity_on_hand) > 500
) sub
ORDER BY ib_income_band_sk, warehouse_rank
LIMIT 10
