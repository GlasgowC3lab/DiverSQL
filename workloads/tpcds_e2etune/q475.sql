SELECT
  ss.ss_store_sk AS store_id,
  d.d_year,
  d.d_quarter_name,
  SUM(ss.ss_net_profit) AS total_net_profit,
  COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
  SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_profit_after_returns,
  AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
  SUM(wp.wp_link_count) AS total_web_page_links,
  COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
  AND sr.sr_returned_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
  AND wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND ca.ca_gmt_offset = -5.00
  AND d.d_year = 2001
GROUP BY ss.ss_store_sk, d.d_year, d.d_quarter_name
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 20
