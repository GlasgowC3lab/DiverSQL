WITH cte_key_diff AS (
       SELECT cr_order_number FROM catalog_returns
       EXCEPT
       SELECT sr_ticket_number FROM store_returns
   ),
   cte_agg AS (
       SELECT
           cr.cr_returned_date_sk,
           i.i_brand,
           s.s_state,
           hd.hd_buy_potential,
           ca.ca_state,
           SUM(cr.cr_return_amount) AS total_return_amount,
           AVG(ws.ws_sales_price) AS avg_sales_price,
           COUNT(*) AS txn_count,
           CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS loss_flag
       FROM catalog_returns cr
       JOIN item i ON cr.cr_item_sk = i.i_item_sk
       JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
       JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
       JOIN store s ON sr.sr_store_sk = s.s_store_sk
       JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
       JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
       JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
       WHERE ca.ca_country = 'United States'
         AND ca.ca_county IN ('Taos County', 'Williams County')
         AND hd.hd_buy_potential = '>10000'
         AND ws.ws_ship_date_sk = 2452365
         AND i.i_current_price > 100
       GROUP BY CUBE(i.i_brand, s.s_state, hd.hd_buy_potential, ca.ca_state, cr.cr_returned_date_sk)
   )
SELECT *
FROM cte_agg
WHERE cr_returned_date_sk NOT IN (SELECT sr_returned_date_sk FROM store_returns)
LIMIT 100
