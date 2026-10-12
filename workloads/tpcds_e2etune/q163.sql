WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty,
           COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    WHERE inv_warehouse_sk = 15
      AND inv_quantity_on_hand > 200
    GROUP BY inv_date_sk
),
wr_agg AS (
    SELECT wr_returned_date_sk AS date_sk,
           SUM(wr_return_quantity) AS total_return_qty,
           SUM(wr_fee) AS total_fee,
           SUM(wr_net_loss) AS total_net_loss,
           AVG(wr_return_amt) AS avg_return_amt
    FROM web_returns
    WHERE wr_fee > 20
    GROUP BY wr_returned_date_sk
)
SELECT i.inv_date_sk,
       i.total_qty,
       i.distinct_items,
       w.total_return_qty,
       w.total_fee,
       w.total_net_loss,
       w.avg_return_amt,
       (w.total_fee / NULLIF(i.total_qty, 0)) AS fee_per_qty,
       RANK() OVER (ORDER BY w.total_net_loss DESC) AS net_loss_rank
FROM inv_agg i
JOIN wr_agg w
    ON i.inv_date_sk = w.date_sk
WHERE w.total_return_qty > 10
ORDER BY w.total_net_loss DESC
LIMIT 100
