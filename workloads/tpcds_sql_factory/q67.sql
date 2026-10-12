WITH site_profit AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS total_profit,
         SUM(ws.ws_ext_sales_price) AS total_sales,
         SUM(ws.ws_ext_tax) AS total_tax
  FROM web_sales ws
  GROUP BY ws.ws_web_site_sk
),
site_return_loss AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(cr.cr_net_loss) AS total_return_loss
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  GROUP BY ws.ws_web_site_sk
),
site_combined AS (
  SELECT sp.site_sk,
         sp.total_profit,
         sp.total_sales,
         sp.total_tax,
         COALESCE(srl.total_return_loss, 0) AS total_return_loss,
         sp.total_profit - COALESCE(srl.total_return_loss, 0) AS net_contribution
  FROM site_profit sp
  LEFT JOIN site_return_loss srl ON sp.site_sk = srl.site_sk
)
SELECT t.site_sk,
       site.web_name,
       site.web_city,
       t.total_profit,
       t.total_return_loss,
       t.net_contribution,
       t.net_contrib_percentile,
       CASE
         WHEN t.net_contrib_percentile >= 0.8 THEN 'Top 20%'
         WHEN t.net_contrib_percentile >= 0.5 THEN 'Middle 30%'
         ELSE 'Bottom 50%'
       END AS performance_tier
FROM (
  SELECT sc.site_sk,
         sc.total_profit,
         sc.total_return_loss,
         sc.net_contribution,
         PERCENT_RANK() OVER (ORDER BY sc.net_contribution) AS net_contrib_percentile
  FROM site_combined sc
) t
JOIN web_site site ON t.site_sk = site.web_site_sk
ORDER BY t.net_contrib_percentile DESC
LIMIT 15
