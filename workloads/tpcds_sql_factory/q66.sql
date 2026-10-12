WITH returns_daily AS (
  SELECT cr.cr_warehouse_sk AS warehouse_sk,
         cr.cr_returned_date_sk AS date_sk,
         SUM(cr.cr_net_loss) AS daily_return_loss,
         SUM(cr.cr_return_quantity) AS daily_return_qty
  FROM catalog_returns cr
  GROUP BY cr.cr_warehouse_sk, cr.cr_returned_date_sk
),
sales_daily AS (
  SELECT ws.ws_warehouse_sk AS warehouse_sk,
         ws.ws_sold_date_sk AS date_sk,
         ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS daily_sales_profit,
         SUM(ws.ws_quantity) AS daily_sales_qty
  FROM web_sales ws
  GROUP BY ws.ws_warehouse_sk, ws.ws_sold_date_sk, ws.ws_web_site_sk
),
combined AS (
  SELECT s.site_sk,
         w.w_city,
         w.w_state,
         COALESCE(r.date_sk, s.date_sk) AS date_sk,
         COALESCE(r.daily_return_loss, 0) AS daily_return_loss,
         COALESCE(s.daily_sales_profit, 0) AS daily_sales_profit,
         COALESCE(r.daily_return_qty, 0) AS daily_return_qty,
         COALESCE(s.daily_sales_qty, 0) AS daily_sales_qty,
         (COALESCE(s.daily_sales_profit,0) - COALESCE(r.daily_return_loss,0)) AS net_contribution
  FROM sales_daily s
  LEFT JOIN returns_daily r 
    ON s.warehouse_sk = r.warehouse_sk 
   AND s.date_sk = r.date_sk
  JOIN warehouse w ON s.warehouse_sk = w.w_warehouse_sk
)
SELECT c.site_sk,
       site.web_name,
       c.date_sk,
       c.net_contribution,
       SUM(c.net_contribution) OVER (PARTITION BY c.site_sk ORDER BY c.date_sk) AS cumulative_net,
       CASE 
         WHEN c.net_contribution > 0 THEN 'Positive'
         WHEN c.net_contribution < 0 THEN 'Negative'
         ELSE 'Zero'
       END AS contribution_flag
FROM combined c
JOIN web_site site ON c.site_sk = site.web_site_sk
WHERE c.date_sk IS NOT NULL
ORDER BY c.site_sk, c.date_sk
LIMIT 100
