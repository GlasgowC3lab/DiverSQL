WITH reason_stats AS (
  SELECT ib.ib_income_band_sk AS income_band_sk,
         ib.ib_lower_bound,
         ib.ib_upper_bound,
         sr.sr_reason_sk,
         COUNT(*) AS reason_cnt,
         AVG(sr.sr_refunded_cash) AS avg_refunded_cash
  FROM store_returns sr
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, sr.sr_reason_sk
),
ranked_reasons AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY income_band_sk ORDER BY reason_cnt DESC) AS reason_rank
  FROM reason_stats
),
top_reasons AS (
  SELECT *
  FROM ranked_reasons
  WHERE reason_rank <= 3
),
sales_avg AS (
  SELECT ib.ib_income_band_sk AS income_band_sk,
         AVG(ws.ws_sales_price) AS avg_sales_price
  FROM web_sales ws
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  GROUP BY ib.ib_income_band_sk
)
SELECT tr.ib_lower_bound,
       tr.ib_upper_bound,
       tr.income_band_sk,
       tr.sr_reason_sk AS return_reason,
       tr.reason_cnt,
       tr.avg_refunded_cash,
       sa.avg_sales_price,
       CASE WHEN tr.avg_refunded_cash > sa.avg_sales_price THEN 'REFUND_HIGHER' ELSE 'SALES_HIGHER' END AS refund_vs_sales,
       RANK() OVER (PARTITION BY tr.income_band_sk ORDER BY tr.avg_refunded_cash DESC) AS refund_amount_rank
FROM top_reasons tr
LEFT JOIN sales_avg sa ON tr.income_band_sk = sa.income_band_sk
ORDER BY tr.income_band_sk, tr.reason_rank
