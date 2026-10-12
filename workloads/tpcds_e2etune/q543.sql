WITH sales AS (
  SELECT d.d_fy_year AS year,
         d.d_quarter_seq AS quarter,
         cd.cd_gender AS gender,
         SUM(cs.cs_net_profit) AS sales_profit,
         COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_fy_year = 2002
  GROUP BY d.d_fy_year, d.d_quarter_seq, cd.cd_gender
),
store_ret AS (
  SELECT d.d_fy_year AS year,
         d.d_quarter_seq AS quarter,
         cd.cd_gender AS gender,
         SUM(sr.sr_net_loss) AS store_return_loss,
         COUNT(*) AS store_ret_cnt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_fy_year = 2002
  GROUP BY d.d_fy_year, d.d_quarter_seq, cd.cd_gender
),
web_ret AS (
  SELECT d.d_fy_year AS year,
         d.d_quarter_seq AS quarter,
         cd.cd_gender AS gender,
         SUM(wr.wr_net_loss) AS web_return_loss,
         COUNT(*) AS web_ret_cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE d.d_fy_year = 2002
  GROUP BY d.d_fy_year, d.d_quarter_seq, cd.cd_gender
)
SELECT s.year,
       s.quarter,
       s.gender,
       s.sales_profit,
       COALESCE(sr.store_return_loss, 0) AS store_return_loss,
       COALESCE(wr.web_return_loss, 0) AS web_return_loss,
       s.sales_profit - COALESCE(sr.store_return_loss, 0) - COALESCE(wr.web_return_loss, 0) AS net_profit,
       s.sales_cnt,
       COALESCE(sr.store_ret_cnt, 0) AS store_ret_cnt,
       COALESCE(wr.web_ret_cnt, 0) AS web_ret_cnt
FROM sales s
LEFT JOIN store_ret sr ON s.year = sr.year AND s.quarter = sr.quarter AND s.gender = sr.gender
LEFT JOIN web_ret wr ON s.year = wr.year AND s.quarter = wr.quarter AND s.gender = wr.gender
ORDER BY net_profit DESC
LIMIT 200
