WITH agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_profit)               AS sum_catalog_profit,
        SUM(ws.ws_net_profit)               AS sum_web_profit,
        SUM(cr.cr_net_loss)                 AS sum_catalog_loss,
        SUM(sr.sr_net_loss)                 AS sum_store_loss,
        AVG(inv.inv_quantity_on_hand)       AS avg_inventory_qty,
        MAX(sm.sm_type)                     AS ship_mode_type
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk      = cs.cs_item_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv
      ON i.i_item_sk = inv.inv_item_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
      ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = i.i_item_sk
    WHERE cr.cr_return_tax > 50
      AND inv.inv_quantity_on_hand > 0
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    agg.i_item_sk,
    agg.i_product_name,
    (agg.sum_catalog_profit + agg.sum_web_profit) - (agg.sum_catalog_loss + agg.sum_store_loss) AS total_profit,
    agg.avg_inventory_qty,
    agg.ship_mode_type
FROM agg
WHERE agg.i_item_sk NOT IN (
    SELECT i_item_sk FROM item WHERE i_brand = 'NonExistentBrand'
)
ORDER BY total_profit DESC
OFFSET 0 LIMIT 100
