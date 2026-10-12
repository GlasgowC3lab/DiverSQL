WITH
  orders_no_return AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
  ),
  sampled_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (5)
  )
SELECT
  i.i_item_id,
  i.i_category,
  i.i_brand,
  cs.cs_order_number,
  cs.cs_net_profit               AS catalog_net_profit,
  ss.ss_net_profit               AS store_net_profit,
  (cs.cs_net_profit + COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
  CASE
    WHEN (cs.cs_net_profit + COALESCE(ss.ss_net_profit, 0)) > 0 THEN 'Profitable'
    ELSE 'Loss'
  END                           AS profit_category,
  (
    SELECT SUM(inv_quantity_on_hand)
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
  )                              AS total_inventory_on_hand,
  DENSE_RANK() OVER (
    PARTITION BY i.i_category
    ORDER BY (cs.cs_net_profit + COALESCE(ss.ss_net_profit, 0)) DESC
  )                               AS profit_rank_in_category
FROM catalog_sales cs
JOIN time_dim td_cs               ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN item i                       ON cs.cs_item_sk = i.i_item_sk
JOIN customer cust_cs            ON cs.cs_bill_customer_sk = cust_cs.c_customer_sk
JOIN catalog_page cp             ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm                ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w                 ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr    ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN reason r_cr            ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_sales ss              ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td_ss              ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN customer cust_ss            ON ss.ss_customer_sk = cust_ss.c_customer_sk
JOIN store s                     ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr      ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN reason r_sr            ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN inventory inv               ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cust_cs.c_birth_day = 19
  AND i.i_brand = 'Brand#12'
  AND s.s_gmt_offset = -5.00
  AND cs.cs_order_number IN (SELECT cs_order_number FROM orders_no_return)
  AND EXISTS (SELECT 1 FROM sampled_inventory si WHERE si.inv_item_sk = i.i_item_sk)
ORDER BY profit_rank_in_category
LIMIT 100
