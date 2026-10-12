SELECT ca.ca_state,
       i.i_category,
       SUM(sr.sr_net_loss) AS total_net_loss,
       SUM(sr.sr_return_quantity) AS total_return_qty,
       AVG(sr.sr_net_loss) AS avg_net_loss,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(sr.sr_net_loss) DESC) AS state_rank_in_category
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE i.i_wholesale_cost > 100
  AND sr.sr_net_loss > 0
  AND ca.ca_country = 'United States'
  AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
GROUP BY ca.ca_state, i.i_category
HAVING SUM(sr.sr_return_quantity) >= 5
ORDER BY total_net_loss DESC
LIMIT 20
