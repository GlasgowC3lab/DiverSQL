WITH item_return_agg AS (
  SELECT
    i.inv_item_sk,
    i.inv_warehouse_sk,
    SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_net_loss) AS total_net_loss
  FROM inventory i
  JOIN web_returns wr
    ON i.inv_item_sk = wr.wr_item_sk
   AND i.inv_date_sk = wr.wr_returned_date_sk
  WHERE i.inv_date_sk BETWEEN 2450800 AND 2451100
    AND wr.wr_returned_date_sk BETWEEN 2450800 AND 2451100
  GROUP BY i.inv_item_sk, i.inv_warehouse_sk
)
SELECT
  sm.sm_carrier,
  ira.inv_item_sk,
  ira.total_qty_on_hand,
  ira.total_return_amt,
  ira.total_return_qty,
  ira.total_net_loss,
  RANK() OVER (PARTITION BY sm.sm_carrier ORDER BY ira.total_net_loss DESC) AS loss_rank
FROM item_return_agg ira
JOIN ship_mode sm
  ON ira.inv_warehouse_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier IS NOT NULL
ORDER BY ira.total_net_loss DESC
LIMIT 100
