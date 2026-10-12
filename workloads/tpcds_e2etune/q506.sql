WITH weekly_sales AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    d.d_week_seq AS week_seq,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS txn_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2022
    AND d.d_quarter_name = 'Q2'
    AND d.d_holiday = 'N'
    AND d.d_weekend = 'N'
  GROUP BY ss.ss_store_sk, d.d_week_seq
)
SELECT
  ws.store_sk,
  ws.week_seq,
  ws.total_net_profit,
  ws.total_sales,
  ws.avg_discount,
  ws.total_net_profit / NULLIF(ws.total_sales, 0) AS profit_margin,
  RANK() OVER (PARTITION BY ws.week_seq ORDER BY ws.total_net_profit DESC) AS profit_rank,
  AVG(ws.total_net_profit) OVER (PARTITION BY ws.store_sk ORDER BY ws.week_seq ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS moving_4week_profit
FROM weekly_sales ws
WHERE ws.total_net_profit > 0
ORDER BY ws.week_seq, profit_rank
LIMIT 100
