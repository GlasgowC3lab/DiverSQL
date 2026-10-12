WITH item_ret AS (
    SELECT it.i_item_sk,
           it.i_category,
           it.i_product_name,
           SUM(sr.sr_return_amt) AS total_return_amt,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    INNER JOIN item it ON sr.sr_item_sk = it.i_item_sk
    GROUP BY it.i_item_sk, it.i_category, it.i_product_name
),
item_inv AS (
    SELECT i.inv_item_sk,
           SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    GROUP BY i.inv_item_sk
)
SELECT ranked.i_category,
       ranked.i_product_name,
       ranked.total_return_amt,
       ranked.total_return_qty,
       ranked.total_net_loss,
       inv.total_inventory_qty,
       ranked.rank_within_category,
       CASE 
           WHEN ranked.rank_within_category <= 3 THEN 'High'
           WHEN ranked.rank_within_category <= 10 THEN 'Medium'
           ELSE 'Low'
       END AS return_level,
       ranked.cumulative_return_amt
FROM (
    SELECT ir.i_item_sk,
           ir.i_category,
           ir.i_product_name,
           ir.total_return_amt,
           ir.total_return_qty,
           ir.total_net_loss,
           DENSE_RANK() OVER (PARTITION BY ir.i_category ORDER BY ir.total_return_amt DESC) AS rank_within_category,
           SUM(ir.total_return_amt) OVER (PARTITION BY ir.i_category ORDER BY ir.total_return_amt DESC
                                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt
    FROM item_ret ir
) ranked
LEFT JOIN item_inv inv ON ranked.i_item_sk = inv.inv_item_sk
WHERE ranked.total_return_qty > 0
ORDER BY ranked.i_category, ranked.rank_within_category
LIMIT 200
