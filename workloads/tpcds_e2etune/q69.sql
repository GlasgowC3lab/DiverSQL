WITH primary_warehouse AS (
    SELECT inv_item_sk, inv_warehouse_sk
    FROM (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_quantity_on_hand DESC) AS rn
        FROM inventory
    ) t
    WHERE rn = 1
)
SELECT
    w.w_warehouse_name,
    i.i_category,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
    AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand,
    RANK() OVER (ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank
FROM store_returns sr
JOIN primary_warehouse pw ON sr.sr_item_sk = pw.inv_item_sk
JOIN warehouse w ON pw.inv_warehouse_sk = w.w_warehouse_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN inventory inv ON pw.inv_item_sk = inv.inv_item_sk AND pw.inv_warehouse_sk = inv.inv_warehouse_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%defect%'
  AND i.i_current_price > 20
  AND inv.inv_quantity_on_hand > 0
GROUP BY w.w_warehouse_name, i.i_category
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
