WITH
store_sales_agg AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  i.i_item_id,
  i.i_category,
  SUM(ss.ss_net_profit) AS net_profit,
  SUM(ss.ss_ext_sales_price) AS sales,
  COUNT(*) AS orders
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_category
),
store_returns_agg AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  i.i_item_id,
  SUM(sr.sr_net_loss) AS return_loss,
  COUNT(*) AS return_cnt
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_item_id
),
catalog_sales_agg AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  i.i_item_id,
  i.i_category,
  SUM(cs.cs_net_profit) AS net_profit,
  SUM(cs.cs_ext_sales_price) AS sales,
  COUNT(*) AS orders
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_category
),
catalog_returns_agg AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  i.i_item_id,
  SUM(cr.cr_net_loss) AS return_loss,
  COUNT(*) AS return_cnt
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_item_id
),
web_sales_agg AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  i.i_item_id,
  i.i_category,
  SUM(ws.ws_net_profit) AS net_profit,
  SUM(ws.ws_ext_sales_price) AS sales,
  COUNT(*) AS orders
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_category
),
web_returns_agg AS (
 SELECT
  d.d_year,
  d.d_month_seq,
  i.i_item_id,
  SUM(wr.wr_net_loss) AS return_loss,
  COUNT(*) AS return_cnt
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_item_id
),
sales_union AS (
 SELECT d_year, d_month_seq, i_item_id, i_category, net_profit, sales, orders, 'Store' AS channel FROM store_sales_agg
 UNION ALL
 SELECT d_year, d_month_seq, i_item_id, i_category, net_profit, sales, orders, 'Catalog' AS channel FROM catalog_sales_agg
 UNION ALL
 SELECT d_year, d_month_seq, i_item_id, i_category, net_profit, sales, orders, 'Web' AS channel FROM web_sales_agg
),
returns_union AS (
 SELECT d_year, d_month_seq, i_item_id, return_loss, return_cnt, 'Store' AS channel FROM store_returns_agg
 UNION ALL
 SELECT d_year, d_month_seq, i_item_id, return_loss, return_cnt, 'Catalog' AS channel FROM catalog_returns_agg
 UNION ALL
 SELECT d_year, d_month_seq, i_item_id, return_loss, return_cnt, 'Web' AS channel FROM web_returns_agg
),
combined AS (
 SELECT
  s.d_year,
  s.d_month_seq,
  s.channel,
  s.i_item_id,
  s.i_category,
  s.net_profit - COALESCE(r.return_loss, 0) AS net_profit_adj,
  s.sales,
  s.orders,
  COALESCE(r.return_cnt, 0) AS return_cnt
 FROM sales_union s
 LEFT JOIN returns_union r
   ON s.d_year = r.d_year
  AND s.d_month_seq = r.d_month_seq
  AND s.i_item_id = r.i_item_id
  AND s.channel = r.channel
)
SELECT
 d_year,
 d_month_seq,
 channel,
 i_item_id,
 i_category,
 net_profit_adj,
 sales,
 orders,
 return_cnt
FROM combined
WHERE net_profit_adj > 0
ORDER BY net_profit_adj DESC
LIMIT 10
