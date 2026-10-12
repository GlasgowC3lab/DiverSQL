WITH site_profit AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS total_profit,
         SUM(ws.ws_ext_sales_price) AS total_sales,
         SUM(ws.ws_ext_tax) AS total_tax,
         AVG(ws.ws_quantity) AS avg_quantity
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk >= 2450000   -- filter recent sales
  GROUP BY ws.ws_web_site_sk
),
site_return_loss AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         COUNT(cr.cr_order_number) AS return_cnt
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2451000
  GROUP BY ws.ws_web_site_sk
),
site_combined AS (
  SELECT sp.site_sk,
         sp.total_profit,
         sp.total_sales,
         sp.total_tax,
         sp.avg_quantity,
         COALESCE(srl.total_return_loss, 0) AS total_return_loss,
         COALESCE(srl.return_cnt, 0) AS return_cnt,
         sp.total_profit - COALESCE(srl.total_return_loss, 0) AS net_contribution
  FROM site_profit sp
  LEFT JOIN site_return_loss srl ON sp.site_sk = srl.site_sk
)
SELECT t.site_sk,
       site.web_name,
       site.web_city,
       t.total_profit,
       t.total_return_loss,
       t.return_cnt,
       t.net_contribution,
       PERCENT_RANK() OVER (ORDER BY t.net_contribution DESC) AS net_contrib_percentile,
       CASE WHEN t.net_contribution > 0 THEN 'Positive' ELSE 'Negative' END AS contribution_sign
FROM site_combined t
JOIN web_site site ON t.site_sk = site.web_site_sk
ORDER BY t.net_contribution DESC
LIMIT 10
