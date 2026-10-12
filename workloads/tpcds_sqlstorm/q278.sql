WITH sales AS (
  SELECT 'store' AS channel, ss.ss_sold_date_sk AS date_sk, ss.ss_item_sk AS item_sk,
         ss.ss_quantity AS quantity, ss.ss_net_paid AS net_paid, ss.ss_net_profit AS net_profit
  FROM store_sales ss
  UNION ALL
  SELECT 'web' AS channel, ws.ws_sold_date_sk, ws.ws_item_sk,
         ws.ws_quantity, ws.ws_net_paid, ws.ws_net_profit
  FROM web_sales ws
  UNION ALL
  SELECT 'catalog' AS channel, cs.cs_sold_date_sk, cs.cs_item_sk,
         cs.cs_quantity, cs.cs_net_paid, cs.cs_net_profit
  FROM catalog_sales cs
)
SELECT
  channel,
  d.d_year,
  i.i_category,
  SUM(net_paid) AS total_net_paid,
  SUM(net_profit) AS total_net_profit,
  SUM(quantity) AS total_quantity,
  COUNT(*) AS txn_count
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY channel, d.d_year, i.i_category
ORDER BY total_net_profit DESC
LIMIT 50
