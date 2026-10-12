WITH returns_agg AS (
  SELECT hd.hd_income_band_sk AS income_band_sk,
         SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  GROUP BY hd.hd_income_band_sk
),
sales_agg AS (
  SELECT hd.hd_income_band_sk AS income_band_sk,
         SUM(ws.ws_net_profit) AS total_net_profit
  FROM web_sales ws
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  GROUP BY hd.hd_income_band_sk
)
SELECT ib.ib_lower_bound,
       ib.ib_upper_bound,
       COALESCE(r.total_net_loss, 0) AS total_net_loss,
       COALESCE(s.total_net_profit, 0) AS total_net_profit,
       COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0) AS net_contribution,
       CASE WHEN COALESCE(r.total_net_loss, 0) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
       RANK() OVER (ORDER BY COALESCE(r.total_net_loss, 0) DESC) AS loss_rank
FROM income_band ib
LEFT JOIN returns_agg r ON ib.ib_income_band_sk = r.income_band_sk
LEFT JOIN sales_agg s ON ib.ib_income_band_sk = s.income_band_sk
WHERE COALESCE(r.total_net_loss, 0) + COALESCE(s.total_net_profit, 0) <> 0
ORDER BY loss_rank
