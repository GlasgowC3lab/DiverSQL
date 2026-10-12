WITH filtered_sales AS (
  SELECT
    ws.ws_warehouse_sk,
    ws.ws_net_profit,
    ws.ws_web_page_sk,
    ws.ws_web_site_sk
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  WHERE regexp_like(wp.wp_url, '/sports/.*')
    AND wsit.web_street_name LIKE 'Washington%'
)
SELECT
  w.w_warehouse_id,
  w.w_warehouse_name,
  CONCAT(w.w_warehouse_name, '_', w.w_city) AS warehouse_full_name,
  SUM(fs.ws_net_profit) AS total_net_profit,
  COUNT(DISTINCT fs.ws_web_page_sk) AS distinct_page_count,
  COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory_qty,
  regexp_extract(w.w_warehouse_name, '(\\w+)$', 1) AS warehouse_name_suffix
FROM filtered_sales fs
JOIN warehouse w ON fs.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY
  w.w_warehouse_id,
  w.w_warehouse_name,
  w.w_city,
  regexp_extract(w.w_warehouse_name, '(\\w+)$', 1)
ORDER BY total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
