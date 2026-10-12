WITH sales_catalog AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_order_number AS order_no,
         cs.cs_quantity AS quantity,
         cs.cs_ext_sales_price AS ext_sales,
         cs.cs_promo_sk AS promo_sk,
         'Catalog' AS channel
  FROM catalog_sales cs
),
sales_web AS (
  SELECT ws.ws_sold_date_sk AS date_sk,
         ws.ws_item_sk AS item_sk,
         ws.ws_order_number AS order_no,
         ws.ws_quantity AS quantity,
         ws.ws_ext_sales_price AS ext_sales,
         ws.ws_promo_sk AS promo_sk,
         'Web' AS channel
  FROM web_sales ws
),
sales_store AS (
  SELECT ss.ss_sold_date_sk AS date_sk,
         ss.ss_item_sk AS item_sk,
         ss.ss_ticket_number AS order_no,
         ss.ss_quantity AS quantity,
         ss.ss_ext_sales_price AS ext_sales,
         ss.ss_promo_sk AS promo_sk,
         'Store' AS channel
  FROM store_sales ss
),
all_sales AS (
  SELECT * FROM sales_catalog
  UNION ALL
  SELECT * FROM sales_web
  UNION ALL
  SELECT * FROM sales_store
),
sales_with_returns AS (
  SELECT s.date_sk,
         s.item_sk,
         s.channel,
         s.quantity,
         s.ext_sales,
         s.promo_sk,
         COALESCE(cr.cr_return_quantity, 0) AS return_qty,
         COALESCE(cr.cr_net_loss, 0) AS return_loss,
         COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
         COALESCE(sr.sr_net_loss, 0) AS store_return_loss,
         COALESCE(wr.wr_return_quantity, 0) AS web_return_qty,
         COALESCE(wr.wr_net_loss, 0) AS web_return_loss
  FROM all_sales s
  LEFT JOIN catalog_returns cr
    ON s.channel = 'Catalog' AND s.order_no = cr.cr_order_number
  LEFT JOIN store_returns sr
    ON s.channel = 'Store' AND s.order_no = sr.sr_ticket_number
  LEFT JOIN web_returns wr
    ON s.channel = 'Web' AND s.order_no = wr.wr_order_number
),
agg_sales AS (
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         i.i_product_name,
         s.channel,
         s.item_sk,
         s.promo_sk,
         SUM(s.ext_sales) AS total_sales,
         SUM(s.return_loss + s.store_return_loss + s.web_return_loss) AS total_return_loss,
         SUM(s.quantity) AS total_quantity,
         SUM(s.return_qty + s.store_return_qty + s.web_return_qty) AS total_return_quantity,
         SUM(s.ext_sales) - SUM(s.return_loss + s.store_return_loss + s.web_return_loss) AS net_sales,
         COALESCE(SUM(s.ext_sales), 0) AS sales_if_null,
         CONCAT(i.i_brand, ' ', i.i_product_name) AS full_product_name,
         COALESCE(p.p_promo_name, 'No Promo') AS promo_name
  FROM sales_with_returns s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 1998 AND 2002
    AND i.i_color IS NOT NULL AND i.i_color <> ''
    AND i.i_size IN ('M', 'L')
  GROUP BY d.d_year,
           i.i_category,
           i.i_brand,
           i.i_product_name,
           s.channel,
           s.item_sk,
           s.promo_sk,
           p.p_promo_name
),
ranked_sales AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS channel_rank,
         RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS year_rank,
         PERCENT_RANK() OVER (ORDER BY total_sales DESC) AS pct_rank
  FROM agg_sales
)
SELECT rs.d_year,
       rs.i_category,
       rs.i_brand,
       rs.full_product_name,
       rs.channel,
       rs.total_sales,
       rs.total_return_loss,
       rs.net_sales,
       rs.channel_rank,
       rs.year_rank,
       rs.pct_rank,
       rs.sales_if_null,
       rs.promo_name,
       rs.promo_sk,
       COALESCE((SELECT MAX(cs.cs_ext_sales_price) FROM catalog_sales cs WHERE cs.cs_item_sk = rs.item_sk), 0) AS max_catalog_price,
       COALESCE((SELECT MAX(ws.ws_ext_sales_price) FROM web_sales ws WHERE ws.ws_item_sk = rs.item_sk), 0) AS max_web_price,
       rs.total_sales * 1.07 AS total_sales_with_tax,
       LENGTH(rs.full_product_name) AS product_name_len,
       CONCAT('Promo:', rs.promo_name) AS promo_label,
       CASE WHEN rs.promo_name = 'No Promo' THEN NULL ELSE rs.promo_name END AS effective_promo,
       CASE WHEN EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = rs.promo_sk AND p2.p_discount_active = 'Y') THEN 'Active' ELSE 'Inactive' END AS promo_status,
       CASE WHEN rs.total_return_loss > 0 THEN 'Returned' ELSE 'NoReturn' END AS return_flag
FROM ranked_sales rs
WHERE rs.net_sales > 5000
  AND rs.channel_rank <= 5
  AND (rs.year_rank = 1 OR rs.pct_rank < 0.1)
ORDER BY rs.d_year, rs.total_sales DESC
LIMIT 100
