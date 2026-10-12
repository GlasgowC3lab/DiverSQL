WITH item_promo AS (
   SELECT
     i.i_item_sk,
     i.i_item_id,
     i.i_brand,
     i.i_category,
     p.p_promo_sk,
     p.p_promo_name,
     p.p_discount_active
   FROM item i
   FULL OUTER JOIN promotion p
     ON p.p_item_sk = i.i_item_sk
),
inventory_summary AS (
   SELECT
     inv.inv_warehouse_sk,
     sum(inv.inv_quantity_on_hand) AS total_qty
   FROM inventory inv
   GROUP BY inv.inv_warehouse_sk
),
base AS (
   SELECT
     cs.cs_item_sk,
     cs.cs_warehouse_sk,
     cs.cs_quantity,
     cs.cs_net_profit,
     cc.cc_name,
     cp.cp_catalog_page_number,
     sm.sm_type,
     w.w_warehouse_name,
     ip.i_brand,
     ip.i_category,
     ip.p_promo_name,
     inv_sum.total_qty AS warehouse_total_qty,
     ws.ws_quantity,
     ws.ws_net_profit,
     wr.wr_return_quantity,
     wr.wr_net_loss
   FROM catalog_sales cs
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item_promo ip
     ON cs.cs_item_sk = ip.i_item_sk
     AND cs.cs_promo_sk = ip.p_promo_sk
   LEFT JOIN LATERAL (
        SELECT total_qty
        FROM inventory_summary inv_sum
        WHERE inv_sum.inv_warehouse_sk = w.w_warehouse_sk
   ) AS inv_sum ON TRUE
   LEFT JOIN web_sales ws
     ON cs.cs_item_sk = ws.ws_item_sk
        AND cs.cs_warehouse_sk = ws.ws_warehouse_sk
   LEFT JOIN web_returns wr
     ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
   WHERE cs.cs_quantity > 0
     AND cs.cs_net_profit > 0
     AND w.w_state = 'CA'
     AND cp.cp_catalog_page_number BETWEEN 5 AND 20
     AND ip.i_brand = 'Brand#12'
     AND cs.cs_item_sk NOT IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand = 0)
)
SELECT
   b.cs_item_sk,
   b.i_brand,
   b.i_category,
   sum(b.cs_quantity) AS total_catalog_qty,
   sum(b.cs_net_profit) AS total_catalog_profit,
   sum(coalesce(b.ws_quantity, 0)) AS total_web_qty,
   sum(coalesce(b.ws_net_profit, 0)) AS total_web_profit,
   sum(coalesce(b.wr_return_quantity, 0)) AS total_returns_qty,
   sum(coalesce(b.wr_net_loss, 0)) AS total_return_loss,
   avg(b.warehouse_total_qty) AS avg_warehouse_inventory
FROM base b
GROUP BY
   b.cs_item_sk,
   b.i_brand,
   b.i_category
HAVING sum(b.cs_net_profit) > 1000
ORDER BY total_catalog_profit DESC
LIMIT 100
