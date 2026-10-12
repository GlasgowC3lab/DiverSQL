WITH joined_data AS (
  SELECT sr.sr_returned_date_sk AS date_key,
         sr.sr_return_amt,
         ws.ws_ext_sales_price,
         ws.ws_ext_discount_amt,
         ib.ib_lower_bound,
         ib.ib_upper_bound
  FROM store_returns sr
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = sr.sr_returned_date_sk
  WHERE ws.ws_bill_hdemo_sk = hd.hd_demo_sk
),
 daily_agg AS (
  SELECT date_key,
         COUNT(*) AS txn_cnt,
         SUM(sr_return_amt) AS total_return_amt,
         SUM(ws_ext_sales_price) AS total_sales_amt,
         AVG(ws_ext_discount_amt) AS avg_discount,
         SUM(sr_return_amt) / NULLIF(SUM(ws_ext_sales_price), 0) AS return_rate,
         MIN(ib_lower_bound) AS income_lower_bound,
         MAX(ib_upper_bound) AS income_upper_bound
  FROM joined_data
  GROUP BY date_key
)
SELECT date_key,
       txn_cnt,
       total_return_amt,
       total_sales_amt,
       avg_discount,
       return_rate,
       CASE WHEN avg_discount > 5 THEN 'HIGH_DISCOUNT' ELSE 'LOW_DISCOUNT' END AS discount_category,
       income_lower_bound,
       income_upper_bound,
       LAG(return_rate) OVER (ORDER BY date_key) AS prev_return_rate,
       return_rate - LAG(return_rate) OVER (ORDER BY date_key) AS return_rate_change,
       CASE 
         WHEN return_rate - LAG(return_rate) OVER (ORDER BY date_key) > 0 THEN 'INCREASE'
         WHEN return_rate - LAG(return_rate) OVER (ORDER BY date_key) < 0 THEN 'DECREASE'
         ELSE 'NO_CHANGE'
       END AS trend
FROM daily_agg
WHERE total_sales_amt > 0
ORDER BY date_key
