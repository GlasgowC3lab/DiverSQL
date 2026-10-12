WITH catalog_agg AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)discount')
      AND cp.cp_type LIKE 'C%'
    GROUP BY cr.cr_order_number
),
web_return_orders AS (
    SELECT DISTINCT wr.wr_order_number
    FROM web_returns wr
),
orders_excluding_web AS (
    SELECT cr_order_number
    FROM catalog_agg
    EXCEPT
    SELECT wr_order_number
    FROM web_return_orders
)
SELECT
    o.cr_order_number AS order_number,
    ca.total_net_loss,
    ca.total_return_qty,
    CASE WHEN ca.total_return_qty > 5 THEN 'HighQty' ELSE 'LowQty' END AS qty_category,
    ws.ws_sold_date_sk,
    ws.ws_net_paid,
    ws.ws_net_profit,
    regexp_extract(wsite.web_name, '(\\w+)$') AS site_suffix
FROM orders_excluding_web o
JOIN catalog_agg ca
  ON o.cr_order_number = ca.cr_order_number
JOIN web_sales ws
  ON ws.ws_order_number = o.cr_order_number
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE ws.ws_net_paid > 0
ORDER BY ca.total_net_loss DESC
LIMIT 100
