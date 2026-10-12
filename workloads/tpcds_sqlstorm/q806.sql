WITH store_sales_agg AS (
  SELECT d.d_year AS sales_year, i.i_category AS category, SUM(ss.ss_net_profit) AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, i.i_category
),
catalog_sales_agg AS (
  SELECT d.d_year AS sales_year, i.i_category AS category, SUM(cs.cs_net_profit) AS profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, i.i_category
),
web_sales_agg AS (
  SELECT d.d_year AS sales_year, i.i_category AS category, SUM(ws.ws_net_profit) AS profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, i.i_category
)
SELECT sales_year, category, SUM(profit) AS total_profit
FROM (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
) t
GROUP BY sales_year, category
ORDER BY total_profit DESC
LIMIT 100
