WITH base AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_ext_sales_price) AS total_sales,
         SUM(ws.ws_net_profit) AS total_profit,
         SUM(ws.ws_ext_tax) AS total_tax,
         COUNT(*) AS trans_cnt
  FROM web_sales ws
  WHERE ws.ws_sold_time_sk % 2 = 0   -- only even time slots
  GROUP BY ws.ws_web_site_sk
),
returns AS (
  SELECT ws.ws_web_site_sk AS site_sk,
         SUM(cr.cr_net_loss) AS total_loss,
         COUNT(cr.cr_order_number) AS return_cnt,
         SUM(cr.cr_return_quantity) AS total_return_qty
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  GROUP BY ws.ws_web_site_sk
)
SELECT b.site_sk,
       site.web_name,
       site.web_country,
       b.total_sales,
       b.total_profit,
       r.total_loss,
       (b.total_profit - r.total_loss) / NULLIF(b.total_sales,0) AS profit_margin,
       RANK() OVER (ORDER BY (b.total_profit - r.total_loss) DESC) AS profit_rank
FROM base b
LEFT JOIN returns r ON b.site_sk = r.site_sk
JOIN web_site site ON b.site_sk = site.web_site_sk
WHERE b.total_sales > 100000
ORDER BY profit_margin DESC
LIMIT 12
