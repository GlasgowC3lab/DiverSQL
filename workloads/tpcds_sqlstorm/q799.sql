WITH trans AS (
  SELECT 'store' AS channel,
         d.d_year AS d_year,
         d.d_moy AS month_num,
         i.i_category AS category,
         ss.ss_net_profit AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT 'catalog' AS channel,
         d.d_year,
         d.d_moy,
         i.i_category,
         cs.cs_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT 'web' AS channel,
         d.d_year,
         d.d_moy,
         i.i_category,
         ws.ws_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  UNION ALL
  SELECT 'store' AS channel,
         d.d_year,
         d.d_moy,
         i.i_category,
         -sr.sr_net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  UNION ALL
  SELECT 'catalog' AS channel,
         d.d_year,
         d.d_moy,
         i.i_category,
         -cr.cr_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  UNION ALL
  SELECT 'web' AS channel,
         d.d_year,
         d.d_moy,
         i.i_category,
         -wr.wr_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
agg AS (
  SELECT
    channel,
    d_year,
    month_num,
    category,
    SUM(profit) AS total_profit,
    COUNT(*) AS txn_count,
    AVG(profit) AS avg_profit,
    SUM(CASE WHEN profit > 0 THEN profit ELSE 0 END) AS profit_positive,
    SUM(CASE WHEN profit < 0 THEN profit ELSE 0 END) AS profit_negative,
    APPROX_PERCENTILE(profit, 0.5) AS median_profit,
    APPROX_PERCENTILE(profit, 0.9) AS p90_profit,
    MAX(profit) AS max_profit,
    MIN(profit) AS min_profit
  FROM trans
  WHERE d_year BETWEEN 1999 AND 2002
  GROUP BY channel, d_year, month_num, category
  HAVING SUM(profit) <> 0
)
SELECT
  channel,
  d_year,
  month_num,
  category,
  total_profit,
  txn_count,
  avg_profit,
  profit_positive,
  profit_negative,
  median_profit,
  p90_profit,
  max_profit,
  min_profit,
  RANK() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank_channel
FROM agg
ORDER BY total_profit DESC
LIMIT 200
