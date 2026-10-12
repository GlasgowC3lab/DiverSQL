SELECT
  t.d_year,
  t.ca_state,
  t.i_category,
  SUM(CASE WHEN t.channel = 'store' THEN t.net_profit ELSE 0 END) AS store_net_profit,
  SUM(CASE WHEN t.channel = 'catalog' THEN t.net_profit ELSE 0 END) AS catalog_net_profit,
  SUM(CASE WHEN t.channel = 'web' THEN t.net_profit ELSE 0 END) AS web_net_profit
FROM (
  SELECT d.d_year AS d_year,
         ca.ca_state AS ca_state,
         i.i_category AS i_category,
         ss.ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT d.d_year,
         ca.ca_state,
         i.i_category,
         cs.cs_net_profit,
         'catalog'
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT d.d_year,
         ca.ca_state,
         i.i_category,
         ws.ws_net_profit,
         'web'
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
) t
GROUP BY t.d_year, t.ca_state, t.i_category
ORDER BY t.d_year, t.ca_state, t.i_category
