WITH cr_filtered AS (
  SELECT
    cr_returning_cdemo_sk,
    cr_warehouse_sk,
    cr_item_sk,
    cr_returned_date_sk,
    cr_return_amount,
    cr_net_loss,
    cr_return_quantity,
    cr_reason_sk
  FROM catalog_returns
  WHERE cr_warehouse_sk IN (5, 7, 8, 10, 17)
    AND cr_reason_sk = 20
    AND cr_return_quantity > 0
),
inv_agg AS (
  SELECT
    inv_warehouse_sk,
    inv_item_sk,
    inv_date_sk,
    SUM(inv_quantity_on_hand) AS total_qty_on_hand
  FROM inventory
  WHERE inv_quantity_on_hand > 0
  GROUP BY inv_warehouse_sk, inv_item_sk, inv_date_sk
)
SELECT
  agg.cr_warehouse_sk,
  agg.ib_income_band_sk,
  agg.num_returns,
  agg.total_return_amount,
  agg.avg_net_loss,
  agg.total_inventory_qty,
  RANK() OVER (PARTITION BY agg.ib_income_band_sk ORDER BY agg.total_return_amount DESC) AS return_amount_rank
FROM (
  SELECT
    cr.cr_warehouse_sk,
    ib.ib_income_band_sk,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(inv.total_qty_on_hand) AS total_inventory_qty
  FROM cr_filtered cr
  JOIN inv_agg inv
    ON cr.cr_item_sk = inv.inv_item_sk
    AND cr.cr_warehouse_sk = inv.inv_warehouse_sk
    AND cr.cr_returned_date_sk = inv.inv_date_sk
  JOIN income_band ib
    ON cr.cr_net_loss BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
  GROUP BY cr.cr_warehouse_sk, ib.ib_income_band_sk
  HAVING COUNT(*) >= 5
) agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
