WITH inv_agg AS (
    SELECT i.inv_item_sk,
           SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    GROUP BY i.inv_item_sk
),
ret_agg AS (
    SELECT sr.sr_store_sk,
           sr.sr_item_sk,
           SUM(sr.sr_net_loss) AS total_net_loss,
           SUM(sr.sr_return_amt) AS total_return_amt,
           COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
)
SELECT s.s_store_id,
       s.s_store_name,
       s.s_city,
       s.s_state,
       SUM(ia.total_qty) AS total_inventory_qty,
       SUM(ra.total_net_loss) AS total_net_loss,
       CASE WHEN SUM(ia.total_qty) = 0 THEN NULL
            ELSE SUM(ra.total_net_loss) / SUM(ia.total_qty) END AS net_loss_per_qty,
       RANK() OVER (ORDER BY CASE WHEN SUM(ia.total_qty) = 0 THEN 0
                                 ELSE SUM(ra.total_net_loss) / SUM(ia.total_qty) END DESC) AS loss_rank
FROM inv_agg ia
INNER JOIN ret_agg ra
  ON ia.inv_item_sk = ra.sr_item_sk
INNER JOIN store s
  ON ra.sr_store_sk = s.s_store_sk
INNER JOIN item it
  ON ia.inv_item_sk = it.i_item_sk
WHERE it.i_category = 'Electronics'
GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state
ORDER BY loss_rank
LIMIT 10
