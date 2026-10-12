WITH cs_agg AS (
  SELECT cs.cs_bill_hdemo_sk AS hd_demo_sk,
         SUM(cs.cs_net_profit) AS total_net_profit,
         AVG(cs.cs_ext_discount_amt) AS avg_discount
  FROM catalog_sales cs
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cs.cs_net_profit > 0
  GROUP BY cs.cs_bill_hdemo_sk
),
sr_agg AS (
  SELECT sr.sr_store_sk,
         sr.sr_hdemo_sk,
         SUM(sr.sr_net_loss) AS total_store_return_loss
  FROM store_returns sr
  GROUP BY sr.sr_store_sk, sr.sr_hdemo_sk
),
wr_agg AS (
  SELECT wr.wr_refunded_hdemo_sk AS hd_demo_sk,
         SUM(wr.wr_net_loss) AS total_web_return_loss
  FROM web_returns wr
  GROUP BY wr.wr_refunded_hdemo_sk
),
store_metrics AS (
  SELECT s.s_store_id,
         s.s_store_name,
         SUM(COALESCE(cs.total_net_profit, 0)) AS total_net_profit,
         SUM(COALESCE(sr.total_store_return_loss, 0)) AS total_store_return_loss,
         SUM(COALESCE(wr.total_web_return_loss, 0)) AS total_web_return_loss,
         (SUM(COALESCE(cs.total_net_profit, 0)) - SUM(COALESCE(sr.total_store_return_loss, 0)) - SUM(COALESCE(wr.total_web_return_loss, 0))) AS net_contribution,
         AVG(COALESCE(cs.avg_discount, 0)) AS avg_discount,
         AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
         ROW_NUMBER() OVER (ORDER BY (SUM(COALESCE(cs.total_net_profit, 0)) - SUM(COALESCE(sr.total_store_return_loss, 0)) - SUM(COALESCE(wr.total_web_return_loss, 0))) DESC) AS rank_by_net_contrib
  FROM store s
  JOIN sr_agg sr ON s.s_store_sk = sr.sr_store_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN cs_agg cs ON hd.hd_demo_sk = cs.hd_demo_sk
  LEFT JOIN wr_agg wr ON hd.hd_demo_sk = wr.hd_demo_sk
  WHERE hd.hd_income_band_sk >= 5
  GROUP BY s.s_store_id, s.s_store_name
  HAVING SUM(COALESCE(cs.total_net_profit, 0)) > 0
)
SELECT s_store_id,
       s_store_name,
       total_net_profit,
       total_store_return_loss,
       total_web_return_loss,
       net_contribution,
       avg_discount,
       avg_vehicle_count
FROM store_metrics
WHERE rank_by_net_contrib <= 10
ORDER BY net_contribution DESC
