WITH store_hourly AS (
  SELECT
    t.t_time_sk,
    t.t_hour,
    SUM(ss.ss_ext_sales_price) AS store_sales_ext_price,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(*) AS store_txn_cnt
  FROM store_sales ss
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY t.t_time_sk, t.t_hour
),
web_hourly AS (
  SELECT
    t.t_time_sk,
    t.t_hour,
    SUM(ws.ws_ext_sales_price) AS web_sales_ext_price,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(*) AS web_txn_cnt
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    AND t.t_hour BETWEEN 9 AND 17
  GROUP BY t.t_time_sk, t.t_hour
),
returns_hourly AS (
  SELECT
    t.t_time_sk,
    t.t_hour,
    cc.cc_division,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
    AND t.t_hour BETWEEN 9 AND 17
    AND cc.cc_division = 3
    AND cc.cc_manager = 'Bob Belcher'
  GROUP BY t.t_time_sk, t.t_hour, cc.cc_division, r.r_reason_desc
)
SELECT
  td.t_hour,
  SUM(COALESCE(s.store_sales_ext_price, 0)) AS total_store_sales,
  SUM(COALESCE(w.web_sales_ext_price, 0)) AS total_web_sales,
  SUM(COALESCE(r.total_return_amount, 0)) AS total_returns,
  SUM(COALESCE(s.store_net_profit, 0)) - SUM(COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns
FROM time_dim td
LEFT JOIN store_hourly s ON td.t_time_sk = s.t_time_sk
LEFT JOIN web_hourly w ON td.t_time_sk = w.t_time_sk
LEFT JOIN returns_hourly r ON td.t_time_sk = r.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
GROUP BY td.t_hour
ORDER BY td.t_hour
