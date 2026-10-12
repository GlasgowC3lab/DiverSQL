WITH site_sales AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_ext_sales_price) AS total_sales,
         SUM(ws.ws_net_paid_inc_tax) AS total_paid_inc_tax,
         COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
  FROM web_sales ws
  WHERE ws.ws_ship_mode_sk IN (1,2,3)
  GROUP BY ws.ws_web_site_sk
),
site_returns AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         AVG(cr.cr_return_quantity) AS avg_return_qty
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  GROUP BY ws.ws_web_site_sk
),
site_metrics AS (
  SELECT s.site_sk,
         s.total_sales,
         s.total_paid_inc_tax,
         s.orders_cnt,
         COALESCE(r.total_return_loss,0) AS total_return_loss,
         COALESCE(r.avg_return_qty,0) AS avg_return_qty,
         (s.total_sales - COALESCE(r.total_return_loss,0)) / NULLIF(s.total_sales,0) AS sales_return_ratio
  FROM site_sales s
  LEFT JOIN site_returns r ON s.site_sk = r.site_sk
)
SELECT sm.site_sk,
       site.web_name,
       site.web_state,
       sm.total_sales,
       sm.total_return_loss,
       sm.sales_return_ratio,
       ROW_NUMBER() OVER (ORDER BY sm.sales_return_ratio DESC) AS rn
FROM site_metrics sm
JOIN web_site site ON sm.site_sk = site.web_site_sk
WHERE sm.sales_return_ratio IS NOT NULL
ORDER BY rn
LIMIT 15
