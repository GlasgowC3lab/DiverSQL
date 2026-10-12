WITH catalog_agg AS (
    SELECT cr.cr_item_sk,
           cr.cr_ship_mode_sk,
           cr.cr_returned_date_sk,
           SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY cr.cr_item_sk, cr.cr_ship_mode_sk, cr.cr_returned_date_sk
),
web_agg AS (
    SELECT wr.wr_item_sk,
           ws.ws_ship_mode_sk AS ship_mode_sk,
           wr.wr_returned_date_sk,
           SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY wr.wr_item_sk, ws.ws_ship_mode_sk, wr.wr_returned_date_sk
),
inventory_agg AS (
    SELECT inv.inv_item_sk,
           inv.inv_date_sk,
           SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    WHERE inv.inv_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY inv.inv_item_sk, inv.inv_date_sk
)
SELECT i.i_item_id,
       i.i_product_name,
       sm.sm_type AS ship_mode,
       ca.cr_returned_date_sk AS return_date_sk,
       ca.catalog_net_loss,
       COALESCE(wa.web_net_loss, 0) AS web_net_loss,
       (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
       ia.total_qty_on_hand,
       RANK() OVER (PARTITION BY sm.sm_type ORDER BY (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) DESC) AS loss_rank_within_ship_mode
FROM catalog_agg ca
JOIN item i ON ca.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON ca.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_agg wa ON wa.wr_item_sk = i.i_item_sk
                      AND wa.wr_returned_date_sk = ca.cr_returned_date_sk
                      AND wa.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk
                           AND ia.inv_date_sk = ca.cr_returned_date_sk
WHERE (ca.catalog_net_loss + COALESCE(wa.web_net_loss, 0)) > 500
ORDER BY total_net_loss DESC
LIMIT 20
