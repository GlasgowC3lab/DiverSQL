WITH date_filter AS (
  SELECT d_date_sk
  FROM date_dim
  WHERE d_year BETWEEN 1999 AND 2002
), 
sales_union AS (
  SELECT cs.cs_item_sk AS item_sk,
         cs.cs_net_profit AS net_profit,
         cs.cs_quantity AS quantity,
         cs.cs_order_number AS order_number,
         cs.cs_call_center_sk AS call_center_sk
  FROM catalog_sales cs
  JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
  UNION ALL
  SELECT ss.ss_item_sk,
         ss.ss_net_profit,
         ss.ss_quantity,
         ss.ss_ticket_number,
         NULL
  FROM store_sales ss
  JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
  UNION ALL
  SELECT ws.ws_item_sk,
         ws.ws_net_profit,
         ws.ws_quantity,
         ws.ws_order_number,
         NULL
  FROM web_sales ws
  JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
), 
returns_union AS (
  SELECT cr.cr_item_sk AS item_sk,
         -cr.cr_net_loss AS net_profit,
         -cr.cr_return_quantity AS quantity,
         cr.cr_order_number AS order_number,
         NULL AS call_center_sk
  FROM catalog_returns cr
  JOIN date_filter df ON cr.cr_returned_date_sk = df.d_date_sk
  UNION ALL
  SELECT sr.sr_item_sk,
         -sr.sr_net_loss,
         -sr.sr_return_quantity,
         sr.sr_ticket_number,
         NULL
  FROM store_returns sr
  JOIN date_filter df ON sr.sr_returned_date_sk = df.d_date_sk
  UNION ALL
  SELECT wr.wr_item_sk,
         -wr.wr_net_loss,
         -wr.wr_return_quantity,
         wr.wr_order_number,
         NULL
  FROM web_returns wr
  JOIN date_filter df ON wr.wr_returned_date_sk = df.d_date_sk
), 
all_activity AS (
  SELECT * FROM sales_union
  UNION ALL
  SELECT * FROM returns_union
), 
combined AS (
  SELECT
    item_sk,
    COALESCE(SUM(net_profit),0) AS total_profit,
    COALESCE(SUM(quantity),0) AS total_qty,
    COUNT(DISTINCT order_number) AS total_orders,
    MAX(call_center_sk) AS any_call_center_sk
  FROM all_activity
  GROUP BY item_sk
), 
item_detail AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_class,
    i.i_current_price,
    CASE
      WHEN i.i_current_price > 0 THEN CONCAT(i.i_product_name, ' - ', i.i_brand)
      ELSE NULL
    END AS product_label
  FROM item i
), 
call_center_detail AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name AS call_center_name,
    cc.cc_manager
  FROM call_center cc
), 
ranked_items AS (
  SELECT
    id.i_item_sk,
    id.i_item_id,
    id.i_product_name,
    id.i_brand,
    id.i_category,
    id.i_class,
    id.i_current_price,
    id.product_label,
    c.total_profit,
    c.total_qty,
    c.total_orders,
    ROW_NUMBER() OVER (PARTITION BY id.i_category ORDER BY c.total_profit DESC) AS profit_rank,
    AVG(c.total_profit) OVER (PARTITION BY id.i_brand) AS avg_brand_profit,
    CASE
      WHEN c.total_profit IS NULL THEN 'No Sales'
      WHEN c.total_profit < 0 THEN 'Loss'
      ELSE 'Profit'
    END AS profit_status,
    (SELECT MAX(c2.total_profit)
     FROM combined c2
     JOIN item i2 ON c2.item_sk = i2.i_item_sk
     WHERE i2.i_category = id.i_category) AS category_max_profit,
    cc.call_center_name,
    cc.cc_manager
  FROM combined c
  LEFT JOIN item_detail id ON c.item_sk = id.i_item_sk
  LEFT JOIN call_center_detail cc ON c.any_call_center_sk = cc.cc_call_center_sk
), 
final AS (
  SELECT
    ri.profit_rank,
    ri.i_item_id,
    ri.product_label,
    ri.i_category,
    ri.i_brand,
    ri.i_class,
    ri.i_current_price,
    ri.total_profit,
    ri.total_qty,
    ri.total_orders,
    ri.avg_brand_profit,
    ri.profit_status,
    ri.category_max_profit,
    ri.call_center_name,
    ri.cc_manager,
    COALESCE(CONCAT('Rank ', CAST(ri.profit_rank AS VARCHAR), ': ', ri.i_item_id), 'N/A') AS ranking_desc,
    CASE
      WHEN ri.total_profit > ri.avg_brand_profit THEN 'Above Avg'
      WHEN ri.total_profit = ri.avg_brand_profit THEN 'Equal Avg'
      ELSE 'Below Avg'
    END AS relative_performance,
    CASE
      WHEN ri.call_center_name IS NULL THEN 'No Call Center'
      ELSE CONCAT('CC: ', ri.call_center_name)
    END AS call_center_info
  FROM ranked_items ri
)
SELECT *
FROM final
WHERE profit_rank <= 10
   OR (profit_status = 'No Sales' AND i_category IS NOT NULL)
ORDER BY i_category, profit_rank
