WITH all_sales AS (
  SELECT
    d.d_year,
    'store' AS channel,
    i.i_category,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  UNION ALL
  SELECT
    d.d_year,
    'catalog' AS channel,
    i.i_category,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  UNION ALL
  SELECT
    d.d_year,
    'web' AS channel,
    i.i_category,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
  d_year,
  channel,
  i_category,
  sum(net_paid) AS total_net_paid,
  sum(net_profit) AS total_net_profit,
  avg(net_paid) AS avg_net_paid
FROM all_sales
GROUP BY d_year, channel, i_category
ORDER BY total_net_paid DESC
LIMIT 100
