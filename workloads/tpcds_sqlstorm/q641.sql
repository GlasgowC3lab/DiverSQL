WITH sales_union AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_quantity AS quantity,
         cs.cs_ext_sales_price AS ext_sales_price,
         cs.cs_net_profit AS net_profit,
         'catalog' AS sales_channel,
         cs.cs_call_center_sk AS entity_sk,
         cs.cs_warehouse_sk AS warehouse_sk,
         cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_quantity,
         ss.ss_ext_sales_price,
         ss.ss_net_profit,
         'store' AS sales_channel,
         ss.ss_store_sk AS entity_sk,
         ss.ss_store_sk AS warehouse_sk,
         ss.ss_promo_sk AS promo_sk
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_ext_sales_price,
         ws.ws_net_profit,
         'web' AS sales_channel,
         ws.ws_web_page_sk AS entity_sk,
         ws.ws_warehouse_sk AS warehouse_sk,
         ws.ws_promo_sk AS promo_sk
  FROM web_sales ws
),
returns_union AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         cr.cr_item_sk AS item_sk,
         cr.cr_return_quantity AS quantity,
         cr.cr_return_amount AS return_amount,
         cr.cr_net_loss AS net_loss,
         'catalog' AS return_channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_item_sk,
         sr.sr_return_quantity,
         sr.sr_return_amt,
         sr.sr_net_loss,
         'store' AS return_channel
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_item_sk,
         wr.wr_return_quantity,
         wr.wr_return_amt,
         wr.wr_net_loss,
         'web' AS return_channel
  FROM web_returns wr
),
sales_agg AS (
  SELECT
    su.date_sk,
    d.d_year,
    i.i_category,
    i.i_brand,
    su.sales_channel,
    MIN(su.entity_sk) AS entity_sk,
    SUM(su.quantity) AS total_qty,
    SUM(su.ext_sales_price) AS total_sales,
    SUM(su.net_profit) AS total_profit,
    COUNT(DISTINCT su.item_sk) AS distinct_items
  FROM sales_union su
  LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
  LEFT JOIN item i ON su.item_sk = i.i_item_sk
  GROUP BY su.date_sk, d.d_year, i.i_category, i.i_brand, su.sales_channel
),
returns_agg AS (
  SELECT
    ru.date_sk,
    d.d_year,
    i.i_category,
    i.i_brand,
    ru.return_channel,
    SUM(ru.quantity) AS total_return_qty,
    SUM(ru.return_amount) AS total_return_amount,
    SUM(ru.net_loss) AS total_net_loss,
    COUNT(DISTINCT ru.item_sk) AS distinct_return_items
  FROM returns_union ru
  LEFT JOIN date_dim d ON ru.date_sk = d.d_date_sk
  LEFT JOIN item i ON ru.item_sk = i.i_item_sk
  GROUP BY ru.date_sk, d.d_year, i.i_category, i.i_brand, ru.return_channel
),
combined AS (
  SELECT
    s.date_sk,
    s.d_year,
    s.i_category,
    s.i_brand,
    s.sales_channel,
    s.entity_sk,
    s.total_qty,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales,
    (s.total_profit - COALESCE(r.total_net_loss, 0)) AS net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.d_year, s.i_category ORDER BY s.total_sales DESC) AS sales_rank_by_category,
    ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY (s.total_sales - COALESCE(r.total_return_amount, 0)) DESC) AS sales_rank_by_year
  FROM sales_agg s
  LEFT JOIN returns_agg r
    ON s.date_sk = r.date_sk
   AND s.i_category = r.i_category
   AND s.i_brand = r.i_brand
   AND s.sales_channel = r.return_channel
)
SELECT
  c.d_year,
  c.i_category,
  UPPER(c.i_category) AS i_category_upper,
  c.i_brand,
  c.sales_channel,
  c.total_qty,
  c.total_sales,
  c.total_profit,
  c.total_return_qty,
  c.total_return_amount,
  c.total_net_loss,
  c.net_sales,
  c.net_profit,
  c.sales_rank_by_category,
  c.sales_rank_by_year,
  SUM(c.total_sales) OVER (PARTITION BY c.sales_channel) AS total_sales_by_channel,
  SUM(c.net_sales) OVER (PARTITION BY c.d_year) AS cumulative_net_sales_by_year,
  (SELECT AVG(sub.total_sales)
   FROM combined sub
   WHERE sub.d_year = c.d_year
     AND sub.i_category = c.i_category) AS avg_sales_in_category_year,
  CASE
    WHEN c.net_sales > 0 AND c.net_profit / NULLIF(c.net_sales, 0) > 0.15 THEN 'high_margin'
    WHEN c.net_sales > 0 AND c.net_profit / NULLIF(c.net_sales, 0) > 0.07 THEN 'mid_margin'
    ELSE 'low_margin'
  END AS profit_margin_category,
  CASE WHEN c.total_return_qty > 0 THEN 'RET' ELSE 'NO_RET' END AS return_flag,
  COALESCE(cc.cc_manager, s_dim.s_manager, wp.wp_url) AS entity_manager_or_url,
  CONCAT('Year ', CAST(c.d_year AS VARCHAR), ': ', c.i_category, ' - ', c.i_brand, ' [', c.sales_channel, ']') AS report_key
FROM combined c
LEFT JOIN call_center cc
  ON c.sales_channel = 'catalog' AND cc.cc_call_center_sk = c.entity_sk
LEFT JOIN store s_dim
  ON c.sales_channel = 'store' AND s_dim.s_store_sk = c.entity_sk
LEFT JOIN web_page wp
  ON c.sales_channel = 'web' AND wp.wp_web_page_sk = c.entity_sk
WHERE c.d_year BETWEEN 2000 AND 2002
  AND c.i_category IS NOT NULL
  AND (c.sales_channel = 'store' OR c.sales_channel = 'web')
  AND c.total_qty > 0
  AND (c.total_sales + c.total_return_amount) > 1000
ORDER BY c.d_year, c.i_category, c.sales_rank_by_category
LIMIT 100
