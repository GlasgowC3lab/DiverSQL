WITH returns_item AS (
  SELECT cr.cr_warehouse_sk AS warehouse_sk,
         cr.cr_item_sk AS item_sk,
         SUM(cr.cr_return_quantity) AS return_qty,
         SUM(cr.cr_return_amount) AS return_amount,
         SUM(cr.cr_net_loss) AS return_loss
  FROM catalog_returns cr
  GROUP BY cr.cr_warehouse_sk, cr.cr_item_sk
),
sales_item AS (
  SELECT ws.ws_warehouse_sk AS warehouse_sk,
         ws.ws_web_site_sk AS site_sk,
         ws.ws_item_sk AS item_sk,
         SUM(ws.ws_quantity) AS sales_qty,
         SUM(ws.ws_sales_price) AS sales_price,
         SUM(ws.ws_net_profit) AS sales_profit
  FROM web_sales ws
  GROUP BY ws.ws_warehouse_sk, ws.ws_web_site_sk, ws.ws_item_sk
),
items_combined AS (
  SELECT 
    COALESCE(r.warehouse_sk, s.warehouse_sk) AS warehouse_sk,
    COALESCE(r.item_sk, s.item_sk) AS item_sk,
    r.return_qty,
    r.return_amount,
    r.return_loss,
    s.sales_qty,
    s.sales_price,
    s.sales_profit,
    s.site_sk
  FROM returns_item r
  FULL OUTER JOIN sales_item s
    ON r.warehouse_sk = s.warehouse_sk AND r.item_sk = s.item_sk
)
SELECT w.w_warehouse_sk,
       w.w_warehouse_name,
       site.web_name,
       ic.item_sk,
       COALESCE(ic.return_qty, 0) AS return_qty,
       COALESCE(ic.sales_qty, 0) AS sales_qty,
       COALESCE(ic.return_amount, 0) AS return_amount,
       COALESCE(ic.sales_price, 0) AS sales_price,
       COALESCE(ic.return_loss, 0) AS return_loss,
       COALESCE(ic.sales_profit, 0) AS sales_profit,
       CASE 
         WHEN COALESCE(ic.sales_price, 0) = 0 THEN NULL
         ELSE (COALESCE(ic.sales_profit, 0) - COALESCE(ic.return_loss, 0)) / COALESCE(ic.sales_price, 0)
       END AS profit_margin,
       DENSE_RANK() OVER (PARTITION BY w.w_warehouse_sk, site.web_site_sk ORDER BY (COALESCE(ic.return_qty,0) + COALESCE(ic.sales_qty,0)) DESC) AS item_rank
FROM items_combined ic
JOIN warehouse w ON ic.warehouse_sk = w.w_warehouse_sk
JOIN web_site site ON ic.site_sk = site.web_site_sk
WHERE (COALESCE(ic.return_qty,0) + COALESCE(ic.sales_qty,0)) > 0
ORDER BY w.w_warehouse_sk, site.web_site_sk, item_rank
LIMIT 20
