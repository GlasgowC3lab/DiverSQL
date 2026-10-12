WITH sales_per_site AS (
  SELECT w.web_site_sk,
         w.web_name,
         w.web_state,
         SUM(ws.ws_net_profit) AS total_sales_profit,
         COUNT(DISTINCT ws.ws_order_number) AS sales_orders
  FROM web_site w
  LEFT JOIN web_sales ws ON ws.ws_web_site_sk = w.web_site_sk
  GROUP BY w.web_site_sk, w.web_name, w.web_state
),
returns_per_site AS (
  SELECT w.web_site_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         COUNT(DISTINCT cr.cr_order_number) AS return_orders
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN web_site w ON 1=1
  JOIN date_dim d_open ON w.web_open_date_sk = d_open.d_date_sk
  JOIN date_dim d_close ON w.web_close_date_sk = d_close.d_date_sk
  WHERE d_ret.d_date BETWEEN d_open.d_date AND d_close.d_date
  GROUP BY w.web_site_sk
)
SELECT s.web_site_sk,
       s.web_name,
       s.web_state,
       s.total_sales_profit,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
       s.sales_orders,
       COALESCE(r.return_orders, 0) AS return_orders,
       NTILE(4) OVER (ORDER BY COALESCE(r.total_return_loss, 0) DESC) AS loss_quartile,
       CUME_DIST() OVER (ORDER BY s.total_sales_profit DESC) AS sales_cume_dist,
       RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC) AS net_profit_rank,
       CASE WHEN COALESCE(r.total_return_loss, 0) > 50000 THEN 'ALERT' ELSE 'OK' END AS loss_alert
FROM sales_per_site s
LEFT JOIN returns_per_site r ON s.web_site_sk = r.web_site_sk
ORDER BY net_profit_rank
LIMIT 50
