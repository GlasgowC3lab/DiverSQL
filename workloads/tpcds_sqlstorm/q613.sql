WITH sm_sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_net_paid,
         ss.ss_net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_net_paid,
         ws.ws_net_profit,
         'web' AS channel
  FROM web_sales ws
)
SELECT d.d_year,
       month(d.d_date) AS month,
       i.i_category,
       s.channel,
       sum(s.net_paid) AS total_net_paid,
       sum(s.net_profit) AS total_net_profit
FROM sm_sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, month(d.d_date), i.i_category, s.channel
ORDER BY d.d_year, month, i_category, total_net_profit DESC
LIMIT 100
