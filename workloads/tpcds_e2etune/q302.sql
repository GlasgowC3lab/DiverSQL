WITH sales_agg AS (
  SELECT cs.cs_item_sk AS item_sk,
         d.d_year,
         d.d_moy AS month,
         SUM(cs.cs_net_paid) AS total_sales,
         SUM(cs.cs_net_profit) AS total_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY cs.cs_item_sk, d.d_year, d.d_moy
),
store_returns_agg AS (
  SELECT sr.sr_item_sk AS item_sk,
         d.d_year,
         d.d_moy AS month,
         SUM(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY sr.sr_item_sk, d.d_year, d.d_moy
),
web_returns_agg AS (
  SELECT wr.wr_item_sk AS item_sk,
         d.d_year,
         d.d_moy AS month,
         SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY wr.wr_item_sk, d.d_year, d.d_moy
),
combined_returns AS (
  SELECT item_sk, d_year, month, SUM(total_return_loss) AS total_return_loss
  FROM (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
  ) r
  GROUP BY item_sk, d_year, month
),
sales_with_returns AS (
  SELECT s.item_sk,
         s.d_year,
         s.month,
         s.total_sales,
         s.total_profit,
         COALESCE(r.total_return_loss, 0) AS total_return_loss,
         s.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales,
         s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit
  FROM sales_agg s
  LEFT JOIN combined_returns r
    ON s.item_sk = r.item_sk
   AND s.d_year = r.d_year
   AND s.month = r.month
)
SELECT i.i_category,
       swr.d_year,
       swr.month,
       SUM(swr.net_sales) AS category_sales,
       SUM(swr.net_profit) AS category_profit,
       RANK() OVER (PARTITION BY swr.d_year, swr.month ORDER BY SUM(swr.net_profit) DESC) AS profit_rank
FROM sales_with_returns swr
JOIN item i ON swr.item_sk = i.i_item_sk
WHERE i.i_category IS NOT NULL
GROUP BY i.i_category, swr.d_year, swr.month
HAVING SUM(swr.net_sales) > 10000
ORDER BY swr.d_year, swr.month, profit_rank
LIMIT 100
