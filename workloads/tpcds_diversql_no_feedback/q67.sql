WITH sales_data AS (
   SELECT
       cs.cs_order_number,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_net_profit,
       cp.cp_department,
       cp.cp_catalog_page_id,
       sm1.sm_type               AS sales_ship_mode_type,
       w1.w_state                AS sales_state,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_net_loss            AS catalog_return_net_loss,
       cr.cr_reason_sk,
       w2.w_state                AS catalog_return_state,
       sm2.sm_type               AS catalog_return_ship_mode_type,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       sr.sr_net_loss            AS store_return_net_loss,
       s.s_store_name,
       s.s_state
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm1
     ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
   JOIN warehouse w1
     ON cs.cs_warehouse_sk = w1.w_warehouse_sk
   JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
   JOIN warehouse w2
     ON cr.cr_warehouse_sk = w2.w_warehouse_sk
   JOIN ship_mode sm2
     ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN reason r2
     ON cr.cr_reason_sk = r2.r_reason_sk
   JOIN store_returns sr
     ON sr.sr_reason_sk = r2.r_reason_sk   -- join via common reason
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
),
agg AS (
   SELECT
       cp_department,
       sales_state,
       SUM(cs_quantity)                    AS total_quantity_sold,
       SUM(cs_net_profit)                  AS total_net_profit,
       SUM(cr_return_quantity)             AS total_catalog_return_qty,
       SUM(cr_return_amount)               AS total_catalog_return_amount,
       SUM(catalog_return_net_loss)        AS total_catalog_return_net_loss,
       SUM(sr_return_quantity)             AS total_store_return_qty,
       SUM(sr_return_amt)                  AS total_store_return_amount,
       SUM(store_return_net_loss)          AS total_store_return_net_loss
   FROM sales_data
   GROUP BY ROLLUP (cp_department, sales_state)
)
SELECT
   COALESCE(cp_department, 'ALL') AS department,
   COALESCE(sales_state,  'ALL') AS state,
   total_quantity_sold,
   total_net_profit,
   total_catalog_return_qty,
   total_catalog_return_amount,
   total_catalog_return_net_loss,
   total_store_return_qty,
   total_store_return_amount,
   total_store_return_net_loss,
   ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS row_num
FROM agg
ORDER BY row_num
LIMIT 100
