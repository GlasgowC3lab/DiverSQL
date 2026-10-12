WITH household_summary AS (
  SELECT hd.hd_demo_sk,
         hd.hd_vehicle_count,
         hd.hd_dep_count,
         ib.ib_lower_bound,
         ib.ib_upper_bound,
         COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
         COALESCE(SUM(sr.sr_net_loss), 0) AS total_loss,
         COALESCE(SUM(ws.ws_net_profit), 0) - COALESCE(SUM(sr.sr_net_loss), 0) AS net_contribution
  FROM household_demographics hd
  LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
  GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count, hd.hd_dep_count,
           ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT hd_demo_sk,
       hd_vehicle_count,
       hd_dep_count,
       ib_lower_bound,
       ib_upper_bound,
       total_profit,
       total_loss,
       net_contribution,
       CASE WHEN net_contribution > 0 THEN 'PROFIT' ELSE 'LOSS' END AS net_category,
       profit_rank
FROM (
  SELECT *,
         DENSE_RANK() OVER (ORDER BY net_contribution DESC) AS profit_rank
  FROM household_summary
) t
WHERE profit_rank <= 10
ORDER BY profit_rank
