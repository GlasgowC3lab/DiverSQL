WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450900 AND 2451060
      AND inv_warehouse_sk IN (1, 9, 10)
    GROUP BY inv_item_sk, inv_date_sk, inv_warehouse_sk
),
ret_agg AS (
    SELECT wr_item_sk AS inv_item_sk,
           wr_returned_date_sk AS inv_date_sk,
           SUM(wr_return_quantity) AS total_ret_qty,
           SUM(wr_return_amt_inc_tax) AS total_ret_amt,
           SUM(wr_net_loss) AS total_net_loss
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450900 AND 2451060
      AND wr_return_amt_inc_tax > 100
    GROUP BY wr_item_sk, wr_returned_date_sk
)
SELECT
    i.inv_item_sk AS item_sk,
    i.inv_warehouse_sk AS warehouse_sk,
    i.inv_date_sk AS date_sk,
    i.total_qty AS inventory_qty,
    r.total_ret_qty AS returned_qty,
    r.total_ret_amt AS returned_amt_inc_tax,
    (r.total_ret_qty * 1.0) / i.total_qty AS return_rate,
    CASE WHEN r.total_ret_qty = 0 THEN NULL ELSE r.total_ret_amt / r.total_ret_qty END AS avg_return_amount,
    r.total_net_loss,
    r.total_net_loss / NULLIF(r.total_ret_amt, 0) AS net_loss_ratio,
    ROW_NUMBER() OVER (ORDER BY (r.total_ret_qty * 1.0) / i.total_qty DESC) AS return_rate_rank
FROM inv_agg i
JOIN ret_agg r
  ON i.inv_item_sk = r.inv_item_sk
 AND i.inv_date_sk = r.inv_date_sk
WHERE
    (r.total_ret_qty * 1.0) / i.total_qty > 0.05
    AND (CASE WHEN r.total_ret_qty = 0 THEN NULL ELSE r.total_ret_amt / r.total_ret_qty END) > 100
ORDER BY
    return_rate DESC,
    avg_return_amount DESC
LIMIT 100
