WITH
  catalog_agg AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      regexp_extract(i.i_item_desc, '(\\d+)', 1) AS item_number,
      SUM(cs.cs_quantity) AS total_qty,
      SUM(cs.cs_net_paid) AS total_sales,
      AVG(cs.cs_net_profit) AS avg_profit,
      MAX(cs.cs_net_profit) AS max_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
      AND i.i_product_name LIKE '%Gold%'
    GROUP BY i.i_item_sk, i.i_product_name, regexp_extract(i.i_item_desc, '(\\d+)', 1)
  ),
  web_agg AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      regexp_extract(i.i_item_desc, '(\\d+)', 1) AS item_number,
      SUM(ws.ws_quantity) AS total_qty,
      SUM(ws.ws_net_paid) AS total_sales,
      AVG(ws.ws_net_profit) AS avg_profit,
      MAX(ws.ws_net_profit) AS max_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
      AND i.i_product_name LIKE '%Gold%'
    GROUP BY i.i_item_sk, i.i_product_name, regexp_extract(i.i_item_desc, '(\\d+)', 1)
  ),
  scalar_max_profit AS (
    SELECT MAX(cs_net_profit) AS max_profit FROM catalog_sales
  ),
  intersect_orders AS (
    SELECT cr_order_number FROM catalog_returns
    INTERSECT
    SELECT wr_order_number FROM web_returns
  ),
  full_joined AS (
    SELECT
      COALESCE(c.i_item_sk, w.i_item_sk) AS item_sk,
      COALESCE(c.i_product_name, w.i_product_name) AS product_name,
      COALESCE(c.total_qty, 0) AS catalog_qty,
      COALESCE(w.total_qty, 0) AS web_qty,
      COALESCE(c.avg_profit, 0) AS catalog_avg_profit,
      COALESCE(w.avg_profit, 0) AS web_avg_profit,
      c.max_profit AS catalog_max_profit,
      w.max_profit AS web_max_profit,
      COALESCE(c.item_number, w.item_number) AS item_number
    FROM catalog_agg c
    FULL OUTER JOIN web_agg w ON c.i_item_sk = w.i_item_sk
  )
SELECT
  fj.item_sk,
  fj.product_name,
  fj.catalog_qty,
  fj.web_qty,
  (fj.catalog_qty + fj.web_qty) AS total_qty,
  fj.catalog_avg_profit,
  fj.web_avg_profit,
  CASE WHEN fj.catalog_max_profit > (SELECT max_profit FROM scalar_max_profit) THEN 'Above' ELSE 'Below' END AS catalog_profit_flag,
  (SELECT COUNT(*) FROM intersect_orders) AS intersect_order_count,
  lateral_extract.item_number,
  CONCAT(fj.product_name, ' - ', lateral_extract.item_number) AS full_label
FROM full_joined fj
LEFT JOIN LATERAL (
  SELECT regexp_extract(fj.product_name, '(\\d+)', 1) AS item_number
) AS lateral_extract ON TRUE
WHERE fj.product_name LIKE '%Gold%'
ORDER BY total_qty DESC
OFFSET 0 ROWS
LIMIT 100
