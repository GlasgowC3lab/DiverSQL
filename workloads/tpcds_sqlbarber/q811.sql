SELECT ca.ca_state,
       COUNT(*) AS return_cnt,
       SUM(sr.sr_net_loss) AS total_net_loss,
       (SELECT ca2.ca_city FROM customer_address ca2 WHERE ca2.ca_address_sk = 35 LIMIT 1) AS sample_city
FROM store_returns sr
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
WHERE ca.ca_state = 'GA'
GROUP BY ca.ca_state
HAVING SUM(sr.sr_net_loss) > 171.36
