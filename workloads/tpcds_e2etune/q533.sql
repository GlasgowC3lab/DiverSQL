WITH store_agg AS (
  SELECT 
    t.t_hour AS hour,
    hd.hd_income_band_sk AS income_band,
    SUM(sr.sr_net_loss) AS store_net_loss,
    COUNT(*) AS store_return_count
  FROM store_returns sr
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_hour BETWEEN 9 AND 21
  GROUP BY t.t_hour, hd.hd_income_band_sk
),
catalog_agg AS (
  SELECT 
    t.t_hour AS hour,
    hd.hd_income_band_sk AS income_band,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(*) AS catalog_return_count
  FROM catalog_returns cr
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_hour BETWEEN 9 AND 21
  GROUP BY t.t_hour, hd.hd_income_band_sk
),
sales_agg AS (
  SELECT 
    t.t_hour AS hour,
    hd.hd_income_band_sk AS income_band,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_transaction_count
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE t.t_hour BETWEEN 9 AND 21
  GROUP BY t.t_hour, hd.hd_income_band_sk
)
SELECT 
  COALESCE(s.hour, c.hour, w.hour) AS hour,
  COALESCE(s.income_band, c.income_band, w.income_band) AS income_band,
  COALESCE(s.store_net_loss, 0) AS store_net_loss,
  COALESCE(c.catalog_net_loss, 0) AS catalog_net_loss,
  COALESCE(w.total_net_profit, 0) AS total_net_profit,
  COALESCE(w.total_sales, 0) AS total_sales,
  COALESCE(w.sales_transaction_count, 0) AS sales_txn_cnt,
  (COALESCE(w.total_net_profit, 0) - COALESCE(s.store_net_loss, 0) - COALESCE(c.catalog_net_loss, 0)) AS net_profit_after_returns
FROM store_agg s
FULL OUTER JOIN catalog_agg c 
  ON s.hour = c.hour AND s.income_band = c.income_band
FULL OUTER JOIN sales_agg w 
  ON COALESCE(s.hour, c.hour) = w.hour 
  AND COALESCE(s.income_band, c.income_band) = w.income_band
ORDER BY hour, income_band
