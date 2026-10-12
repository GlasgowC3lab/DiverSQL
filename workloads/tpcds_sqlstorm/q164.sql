WITH all_sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit, 'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_net_profit, 'store'
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_net_profit, 'web'
  FROM web_sales ws
),
sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         s.channel,
         SUM(s.net_profit) AS total_net_profit
  FROM all_sales s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, s.channel
  HAVING SUM(s.net_profit) > 0
)
SELECT
  d_year,
  i_category,
  channel,
  total_net_profit,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, profit_rank
