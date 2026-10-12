WITH open_dates AS (
  SELECT cc.cc_call_center_sk,
         cc.cc_name,
         d.d_year AS open_year,
         d.d_month_seq AS open_month_seq
  FROM call_center cc
  JOIN date_dim d
    ON cc.cc_open_date_sk = d.d_date_sk
  WHERE cc.cc_manager IN ('Bob Belcher', 'Larry Mccray')
),

store_sales_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(ss.ss_net_profit) AS store_net_profit
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq
),

web_sales_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(ws.ws_net_profit) AS web_net_profit
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_month_seq
),

returns_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         SUM(cr.cr_net_loss) AS return_net_loss,
         COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 9 AND 17
  GROUP BY d.d_year, d.d_month_seq
)

SELECT od.cc_name,
       od.open_year,
       od.open_month_seq AS month_seq,
       COALESCE(ss.store_net_profit, 0) AS total_store_net_profit,
       COALESCE(ws.web_net_profit, 0) AS total_web_net_profit,
       COALESCE(r.return_net_loss, 0) AS total_return_net_loss,
       (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(r.return_net_loss, 0)) AS net_total_profit,
       COALESCE(r.return_cnt, 0) AS return_count
FROM open_dates od
LEFT JOIN store_sales_agg ss
  ON ss.d_year = od.open_year
 AND ss.d_month_seq = od.open_month_seq
LEFT JOIN web_sales_agg ws
  ON ws.d_year = od.open_year
 AND ws.d_month_seq = od.open_month_seq
LEFT JOIN returns_agg r
  ON r.d_year = od.open_year
 AND r.d_month_seq = od.open_month_seq
WHERE (COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(r.return_net_loss, 0)) > 0
ORDER BY net_total_profit DESC
LIMIT 10
