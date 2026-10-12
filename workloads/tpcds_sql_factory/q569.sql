WITH profit_by_site AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS profit,
         SUM(ws.ws_ext_sales_price) AS sales,
         MAX(ws.ws_net_paid) AS max_paid
  FROM web_sales ws
  GROUP BY ws.ws_web_site_sk
),
loss_by_site AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(cr.cr_net_loss) AS loss,
         MIN(cr.cr_return_quantity) AS min_return_qty
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  GROUP BY ws.ws_web_site_sk
)
SELECT p.site_sk,
       site.web_name,
       site.web_city,
       p.profit,
       l.loss,
       p.profit - l.loss AS net_profit,
       NTILE(4) OVER (ORDER BY (p.profit - l.loss) DESC) AS profit_quartile,
       CASE WHEN (p.profit - l.loss) > 0 THEN 'Gain' ELSE 'Loss' END AS profit_status
FROM profit_by_site p
LEFT JOIN loss_by_site l ON p.site_sk = l.site_sk
JOIN web_site site ON p.site_sk = site.web_site_sk
ORDER BY net_profit DESC
LIMIT 20
