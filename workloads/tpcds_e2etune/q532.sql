WITH cs_agg AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS cs_transactions
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE cc.cc_gmt_offset = -5.00
    AND cc.cc_division = 3
    AND d.d_year = 2001
  GROUP BY cc.cc_call_center_id, cc.cc_name, d.d_year, d.d_month_seq
),
sr_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(*) AS return_transactions
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
)
SELECT
  cs.cc_call_center_id,
  cs.cc_name,
  cs.d_year,
  cs.d_month_seq,
  cs.total_net_profit,
  cs.total_discount,
  cs.cs_transactions,
  COALESCE(sr.total_return_loss, 0) AS total_return_loss,
  COALESCE(sr.return_transactions, 0) AS return_transactions,
  (cs.total_net_profit - COALESCE(sr.total_return_loss, 0)) AS net_contribution,
  RANK() OVER (PARTITION BY cs.d_year ORDER BY (cs.total_net_profit - COALESCE(sr.total_return_loss, 0)) DESC) AS profit_rank
FROM cs_agg cs
LEFT JOIN sr_agg sr
  ON cs.d_year = sr.d_year
 AND cs.d_month_seq = sr.d_month_seq
ORDER BY cs.d_year, net_contribution DESC
LIMIT 100
