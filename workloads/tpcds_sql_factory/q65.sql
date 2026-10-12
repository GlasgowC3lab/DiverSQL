WITH return_by_warehouse AS (
  SELECT cr.cr_warehouse_sk AS warehouse_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         SUM(cr.cr_return_quantity) AS total_return_qty
  FROM catalog_returns cr
  GROUP BY cr.cr_warehouse_sk
),
sales_by_warehouse_site AS (
  SELECT ws.ws_warehouse_sk AS warehouse_sk,
         ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS total_sales_profit,
         SUM(ws.ws_ext_sales_price) AS total_sales_amount,
         SUM(ws.ws_quantity) AS total_sales_qty
  FROM web_sales ws
  GROUP BY ws.ws_warehouse_sk, ws.ws_web_site_sk
)
SELECT w.w_warehouse_sk,
       w.w_warehouse_name,
       r.total_return_loss,
       s.total_sales_profit,
       CASE WHEN s.total_sales_profit = 0 THEN NULL ELSE r.total_return_loss / s.total_sales_profit END AS loss_to_profit_ratio,
       RANK() OVER (ORDER BY CASE WHEN s.total_sales_profit = 0 THEN 0 ELSE r.total_return_loss / s.total_sales_profit END DESC) AS loss_profit_rank,
       site.web_name AS site_name
FROM warehouse w
LEFT JOIN return_by_warehouse r ON w.w_warehouse_sk = r.warehouse_sk
JOIN sales_by_warehouse_site s ON w.w_warehouse_sk = s.warehouse_sk
JOIN web_site site ON s.site_sk = site.web_site_sk
WHERE r.total_return_loss IS NOT NULL
ORDER BY loss_profit_rank
LIMIT 10
