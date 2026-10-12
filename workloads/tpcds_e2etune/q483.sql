WITH sales_agg AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    td.t_shift,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY ss.ss_store_sk, td.t_shift
),
returns_agg AS (
  SELECT
    sr.sr_store_sk AS store_sk,
    td.t_shift,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns_inc_tax,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(*) AS returns_cnt
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY sr.sr_store_sk, td.t_shift
)
SELECT
  s.s_store_name,
  s.s_market_id,
  sa.t_shift,
  sa.total_sales_inc_tax,
  sa.total_profit,
  sa.avg_discount,
  sa.sales_cnt,
  COALESCE(ra.total_returns_inc_tax, 0) AS total_returns_inc_tax,
  COALESCE(ra.total_return_loss, 0) AS total_return_loss,
  COALESCE(ra.returns_cnt, 0) AS returns_cnt,
  (sa.total_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
  RANK() OVER (PARTITION BY sa.t_shift ORDER BY (sa.total_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank_by_shift
FROM sales_agg sa
JOIN store s ON sa.store_sk = s.s_store_sk
LEFT JOIN returns_agg ra ON sa.store_sk = ra.store_sk AND sa.t_shift = ra.t_shift
WHERE s.s_rec_start_date >= DATE '1999-01-01'
  AND s.s_market_id IN (2, 4, 8)
ORDER BY sa.t_shift, profit_rank_by_shift
