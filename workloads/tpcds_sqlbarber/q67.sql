SELECT
  ss.ss_store_sk,
  ca.ca_state,
  cs.cs_item_sk,
  SUM(ss.ss_net_paid) AS total_store_sales,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2) AS max_return_amount
FROM store_sales ss
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
WHERE ss.ss_sold_date_sk = 2452187
  AND cs.cs_sold_date_sk = 2450825
GROUP BY ss.ss_store_sk, ca.ca_state, cs.cs_item_sk
HAVING SUM(ss.ss_net_paid) > 330.78
   AND COUNT(DISTINCT ss.ss_ticket_number) >= 1
