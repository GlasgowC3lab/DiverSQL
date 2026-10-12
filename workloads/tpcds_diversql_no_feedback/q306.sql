WITH sales_filtered AS (
   SELECT cs.cs_order_number,
          cs.cs_item_sk,
          cs.cs_ship_mode_sk,
          cs.cs_warehouse_sk,
          cs.cs_sold_date_sk,
          cs.cs_ext_tax,
          cs.cs_net_profit
   FROM catalog_sales cs
   WHERE cs.cs_sold_date_sk BETWEEN 2451050 AND 2451080
     AND cs.cs_ext_tax > 60
     AND cs.cs_ship_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_carrier = 'BOXBUNDLES')
     AND cs.cs_warehouse_sk IN (SELECT w.w_warehouse_sk FROM warehouse w WHERE w.w_state = 'CA')
),

inv_wh_full AS (
   SELECT i.inv_date_sk,
          i.inv_item_sk,
          i.inv_warehouse_sk,
          i.inv_quantity_on_hand,
          w.w_warehouse_sk,
          w.w_warehouse_name,
          w.w_state
   FROM inventory i
   FULL OUTER JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
)

SELECT *
FROM (
   SELECT
          wh.w_warehouse_name AS warehouse_name,
          sm.sm_carrier AS carrier,
          SUM(sf.cs_net_profit) AS total_net_profit,
          SUM(cr.cr_return_amount) AS total_return_amount,
          SUM(iwh.inv_quantity_on_hand) AS total_qty_on_hand,
          RANK() OVER (PARTITION BY wh.w_warehouse_name ORDER BY SUM(sf.cs_net_profit) DESC) AS profit_rank
   FROM sales_filtered sf
   JOIN ship_mode sm
     ON sf.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse wh
     ON sf.cs_warehouse_sk = wh.w_warehouse_sk
   FULL OUTER JOIN inv_wh_full iwh
     ON wh.w_warehouse_sk = iwh.inv_warehouse_sk
   LEFT JOIN catalog_returns cr
     ON sf.cs_order_number = cr.cr_order_number
        AND sf.cs_item_sk = cr.cr_item_sk
   WHERE sm.sm_carrier = 'BOXBUNDLES'
   GROUP BY wh.w_warehouse_name, sm.sm_carrier

   UNION DISTINCT

   SELECT
          wh.w_warehouse_name AS warehouse_name,
          sm.sm_carrier AS carrier,
          SUM(sf.cs_net_profit) AS total_net_profit,
          SUM(cr.cr_return_amount) AS total_return_amount,
          SUM(iwh.inv_quantity_on_hand) AS total_qty_on_hand,
          RANK() OVER (PARTITION BY wh.w_warehouse_name ORDER BY SUM(sf.cs_net_profit) DESC) AS profit_rank
   FROM sales_filtered sf
   JOIN ship_mode sm
     ON sf.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse wh
     ON sf.cs_warehouse_sk = wh.w_warehouse_sk
   FULL OUTER JOIN inv_wh_full iwh
     ON wh.w_warehouse_sk = iwh.inv_warehouse_sk
   LEFT JOIN catalog_returns cr
     ON sf.cs_order_number = cr.cr_order_number
        AND sf.cs_item_sk = cr.cr_item_sk
   WHERE sm.sm_carrier = 'ORIENTAL'
   GROUP BY wh.w_warehouse_name, sm.sm_carrier
) final_result
ORDER BY total_net_profit DESC
LIMIT 100
