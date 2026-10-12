WITH
store_channel AS (
  SELECT d.d_year,
         d.d_quarter_seq AS quarter,
         i.i_category,
         SUM(ss.ss_net_profit) AS store_profit,
         SUM(ss.ss_net_paid) AS store_sales
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
catalog_channel AS (
  SELECT d.d_year,
         d.d_quarter_seq AS quarter,
         i.i_category,
         SUM(cs.cs_net_profit) AS catalog_profit,
         SUM(cs.cs_net_paid) AS catalog_sales
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
web_channel AS (
  SELECT d.d_year,
         d.d_quarter_seq AS quarter,
         i.i_category,
         SUM(ws.ws_net_profit) AS web_profit,
         SUM(ws.ws_net_paid) AS web_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, d.d_quarter_seq, i.i_category
)
SELECT
  COALESCE(s.d_year, c.d_year, w.d_year) AS year,
  COALESCE(s.quarter, c.quarter, w.quarter) AS quarter,
  COALESCE(s.i_category, c.i_category, w.i_category) AS category,
  s.store_sales,
  c.catalog_sales,
  w.web_sales,
  s.store_profit,
  c.catalog_profit,
  w.web_profit,
  (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0) + COALESCE(w.web_sales, 0)) AS total_sales,
  (COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0)) AS total_profit,
  CASE
    WHEN (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0) + COALESCE(w.web_sales, 0)) = 0 THEN 0
    ELSE (COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0)) /
         (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0) + COALESCE(w.web_sales, 0))
  END AS overall_profit_margin
FROM store_channel s
FULL OUTER JOIN catalog_channel c
  ON s.d_year = c.d_year AND s.quarter = c.quarter AND s.i_category = c.i_category
FULL OUTER JOIN web_channel w
  ON COALESCE(s.d_year, c.d_year) = w.d_year
   AND COALESCE(s.quarter, c.quarter) = w.quarter
   AND COALESCE(s.i_category, c.i_category) = w.i_category
ORDER BY total_sales DESC
LIMIT 100
