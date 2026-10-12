SELECT d.d_year,
       d.d_month_seq AS month_seq,
       ca_ret.ca_state AS returning_state,
       ca_ref.ca_state AS refunded_state,
       s.s_store_name,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_net_loss) AS total_net_loss,
       AVG(cr.cr_return_quantity) AS avg_return_qty,
       SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
       AVG(s.s_tax_percentage) AS avg_store_tax_pct
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND cr.cr_return_amount > 50
  AND s.s_state = ca_ret.ca_state
GROUP BY d.d_year, d.d_month_seq, ca_ret.ca_state, ca_ref.ca_state, s.s_store_name
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
