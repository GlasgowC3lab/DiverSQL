WITH return_by_warehouse AS (
  SELECT cr.cr_warehouse_sk AS warehouse_sk,
         SUM(cr.cr_net_loss) AS total_return_loss,
         COUNT(DISTINCT cr.cr_reason_sk) AS distinct_reason_cnt
  FROM catalog_returns cr
  WHERE cr.cr_return_quantity > 5
  GROUP BY cr.cr_warehouse_sk
),
sales_by_warehouse_site AS (
  SELECT ws.ws_warehouse_sk AS warehouse_sk,
         ws.ws_web_site_sk AS site_sk,
         SUM(ws.ws_net_profit) AS total_sales_profit,
         SUM(ws.ws_ext_sales_price) AS total_sales_amount,
         SUM(ws.ws_quantity) AS total_sales_qty,
         SUM(ws.ws_coupon_amt) AS total_coupons
  FROM web_sales ws
  WHERE ws.ws_coupon_amt > 0
  GROUP BY ws.ws_warehouse_sk, ws.ws_web_site_sk
)
SELECT w.w_warehouse_sk,
       w.w_warehouse_name,
       r.total_return_loss,
       r.distinct_reason_cnt,
       s.total_sales_amount,
       s.total_coupons,
       (r.total_return_loss - s.total_coupons) AS net_loss_after_coupons,
       RANK() OVER (ORDER BY (r.total_return_loss - s.total_coupons) DESC) AS net_loss_rank,
       site.web_name AS site_name
FROM warehouse w
LEFT JOIN return_by_warehouse r ON w.w_warehouse_sk = r.warehouse_sk
JOIN sales_by_warehouse_site s ON w.w_warehouse_sk = s.warehouse_sk
JOIN web_site site ON s.site_sk = site.web_site_sk
WHERE r.total_return_loss IS NOT NULL
  AND w.w_gmt_offset BETWEEN -5 AND -3
ORDER BY net_loss_rank
LIMIT 7
