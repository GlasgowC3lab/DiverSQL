WITH return_by_warehouse AS (
  SELECT cr.cr_warehouse_sk AS warehouse_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         COUNT(*) AS return_events,
         AVG(cr.cr_return_quantity) AS avg_return_qty
  FROM catalog_returns cr
  WHERE cr.cr_returned_date_sk >= 20000101
  GROUP BY cr.cr_warehouse_sk
),
sales_by_warehouse_site AS (
  SELECT ws.ws_warehouse_sk AS warehouse_sk,
         ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS total_sales_profit,
         SUM(ws.ws_ext_sales_price) AS total_sales_amount,
         SUM(ws.ws_quantity) AS total_sales_qty,
         MAX(ws.ws_net_paid_inc_tax) AS max_paid_inc_tax
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 20000101 AND 20001231
  GROUP BY ws.ws_warehouse_sk, ws.ws_web_site_sk
)
SELECT w.w_warehouse_sk,
       w.w_warehouse_name,
       r.total_return_loss,
       s.total_sales_profit,
       r.return_events,
       CASE WHEN s.total_sales_profit = 0 THEN NULL ELSE r.total_return_loss / s.total_sales_profit END AS loss_to_profit_ratio,
       DENSE_RANK() OVER (ORDER BY r.total_return_loss DESC) AS loss_rank,
       site.web_name AS site_name,
       s.max_paid_inc_tax
FROM warehouse w
LEFT JOIN return_by_warehouse r ON w.w_warehouse_sk = r.warehouse_sk
JOIN sales_by_warehouse_site s ON w.w_warehouse_sk = s.warehouse_sk
JOIN web_site site ON s.site_sk = site.web_site_sk
WHERE r.total_return_loss IS NOT NULL
  AND w.w_state = 'CA'
ORDER BY loss_to_profit_ratio DESC NULLS LAST
LIMIT 5
