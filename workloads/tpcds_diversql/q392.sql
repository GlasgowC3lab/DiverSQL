WITH orders_no_ret AS (
       SELECT cs_order_number
       FROM catalog_sales
       EXCEPT
       SELECT cr_order_number
       FROM catalog_returns
   ),
   filtered_items AS (
       SELECT i_item_sk
       FROM item
       WHERE i_item_desc LIKE '%Legal%'
   )
SELECT
   i_cs.i_item_id,
   i_cs.i_item_desc,
   cp.cp_catalog_number,
   COUNT(DISTINCT cs.cs_order_number)                         AS total_orders,
   SUM(cs.cs_net_paid)                                        AS total_sales,
   SUM(COALESCE(sr_full.sr_return_amt, 0))                    AS total_return_amount,
   SUM(COALESCE(inv.inv_quantity_on_hand, 0))                AS total_inventory_on_hand,
   COUNT(DISTINCT CASE WHEN cs.cs_order_number IN (
           SELECT cs_order_number FROM orders_no_ret) THEN cs.cs_order_number END) AS orders_without_return
FROM catalog_sales cs
JOIN time_dim td_cs
  ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN customer cust_bill
  ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i_cs
  ON cs.cs_item_sk = i_cs.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i_cs.i_item_sk
LEFT JOIN store_sales ss
  ON ss.ss_item_sk = i_cs.i_item_sk
LEFT JOIN time_dim td_ss
  ON ss.ss_sold_time_sk = td_ss.t_time_sk
LEFT JOIN customer cust_store
  ON ss.ss_customer_sk = cust_store.c_customer_sk
LEFT JOIN customer_address ca_store
  ON ss.ss_addr_sk = ca_store.ca_address_sk
FULL OUTER JOIN (
       SELECT sr.sr_ticket_number,
              sr.sr_item_sk,
              r.r_reason_desc,
              sr.sr_return_amt
       FROM store_returns sr
       JOIN reason r
         ON sr.sr_reason_sk = r.r_reason_sk
   ) sr_full
  ON sr_full.sr_item_sk = i_cs.i_item_sk
WHERE td_cs.t_shift = 'first'
  AND i_cs.i_item_sk IN (SELECT i_item_sk FROM filtered_items)
GROUP BY i_cs.i_item_id, i_cs.i_item_desc, cp.cp_catalog_number
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
