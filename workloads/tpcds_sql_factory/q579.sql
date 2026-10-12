WITH return_by_warehouse AS (
  SELECT cr.cr_warehouse_sk AS warehouse_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         SUM(cr.cr_return_quantity) AS total_return_qty,
         MIN(cr.cr_return_amt_inc_tax) AS min_return_amount
  FROM catalog_returns cr
  GROUP BY cr.cr_warehouse_sk
),
sales_by_warehouse_site AS (
  SELECT ws.ws_warehouse_sk AS warehouse_sk,
         ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS total_sales_profit,
         SUM(ws.ws_ext_sales_price) AS total_sales_amount,
         SUM(ws.ws_quantity) AS total_sales_qty,
         AVG(ws.ws_sales_price) AS avg_sales_price,
         SUM(ws.ws_ext_tax) AS total_sales_tax
  FROM web_sales ws
  GROUP BY ws.ws_warehouse_sk, ws.ws_web_site_sk
)
SELECT w.w_warehouse_sk,
       w.w_city,
       r.total_return_qty,
       s.total_sales_qty,
       r.min_return_amount,
       s.avg_sales_price,
       DENSE_RANK() OVER (PARTITION BY w.w_state ORDER BY (s.total_sales_amount - r.total_return_loss) DESC) AS profit_rank,
       site.web_name AS site_name,
       CONCAT(w.w_state, '-', site.web_state) AS combined_state
FROM warehouse w
LEFT JOIN return_by_warehouse r ON w.w_warehouse_sk = r.warehouse_sk
JOIN sales_by_warehouse_site s ON w.w_warehouse_sk = s.warehouse_sk
JOIN web_site site ON s.site_sk = site.web_site_sk
WHERE w.w_country = 'United States'
  AND (s.total_sales_amount - r.total_return_loss) > 0
ORDER BY profit_rank, w.w_city
LIMIT 12
