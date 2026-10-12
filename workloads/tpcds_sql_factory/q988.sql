WITH inv_daily AS (
    SELECT i.inv_warehouse_sk,
           i.inv_item_sk,
           i.inv_date_sk,
           SUM(i.inv_quantity_on_hand) AS qty_on_hand
    FROM inventory i
    GROUP BY i.inv_warehouse_sk, i.inv_item_sk, i.inv_date_sk
),
ret_daily_store AS (
    SELECT sr.sr_item_sk,
           sr.sr_returned_date_sk,
           sr.sr_store_sk,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, sr.sr_store_sk
),
joined AS (
    SELECT id.inv_warehouse_sk,
           id.inv_item_sk,
           id.inv_date_sk,
           id.qty_on_hand,
           rds.total_return_qty,
           rds.total_return_amt,
           it.i_product_name,
           s.s_store_id,
           s.s_store_name
    FROM inv_daily id
    LEFT JOIN ret_daily_store rds
      ON id.inv_item_sk = rds.sr_item_sk
     AND id.inv_date_sk = rds.sr_returned_date_sk
    INNER JOIN item it ON id.inv_item_sk = it.i_item_sk
    LEFT JOIN store s ON rds.sr_store_sk = s.s_store_sk
)
SELECT *,
       qty_on_hand - prev_qty_on_hand AS qty_change,
       CASE WHEN qty_on_hand - prev_qty_on_hand < 0 AND total_return_qty > 0 THEN 'Potential Stockout' ELSE 'Normal' END AS stock_status
FROM (
    SELECT j.*, 
           LAG(j.qty_on_hand) OVER (PARTITION BY j.inv_warehouse_sk, j.inv_item_sk ORDER BY j.inv_date_sk) AS prev_qty_on_hand
    FROM joined j
) t
WHERE t.qty_on_hand IS NOT NULL
ORDER BY t.inv_warehouse_sk, t.inv_item_sk, t.inv_date_sk
LIMIT 100
