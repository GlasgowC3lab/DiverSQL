WITH
store_sales_agg AS (
 SELECT
  d.d_year,
  i.i_category,
  'store' AS channel,
  SUM(ss.ss_net_profit) AS net_profit,
  SUM(ss.ss_quantity) AS quantity_sold,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_ext_discount_amt) AS total_discount,
  COUNT(DISTINCT ss.ss_ticket_number) AS orders
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
 GROUP BY d.d_year, i.i_category
),
catalog_sales_agg AS (
 SELECT
  d.d_year,
  i.i_category,
  'catalog' AS channel,
  SUM(cs.cs_net_profit) AS net_profit,
  SUM(cs.cs_quantity) AS quantity_sold,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  SUM(cs.cs_ext_discount_amt) AS total_discount,
  COUNT(DISTINCT cs.cs_order_number) AS orders
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
 GROUP BY d.d_year, i.i_category
),
web_sales_agg AS (
 SELECT
  d.d_year,
  i.i_category,
  'web' AS channel,
  SUM(ws.ws_net_profit) AS net_profit,
  SUM(ws.ws_quantity) AS quantity_sold,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_ext_discount_amt) AS total_discount,
  COUNT(DISTINCT ws.ws_order_number) AS orders
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
 GROUP BY d.d_year, i.i_category
),
store_returns_agg AS (
 SELECT
  d.d_year,
  i.i_category,
  'store' AS channel,
  SUM(sr.sr_return_quantity) AS return_quantity,
  SUM(sr.sr_return_amt) AS return_amount,
  SUM(sr.sr_net_loss) AS return_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
),
catalog_returns_agg AS (
 SELECT
  d.d_year,
  i.i_category,
  'catalog' AS channel,
  SUM(cr.cr_return_quantity) AS return_quantity,
  SUM(cr.cr_return_amount) AS return_amount,
  SUM(cr.cr_net_loss) AS return_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
),
web_returns_agg AS (
 SELECT
  d.d_year,
  i.i_category,
  'web' AS channel,
  SUM(wr.wr_return_quantity) AS return_quantity,
  SUM(wr.wr_return_amt) AS return_amount,
  SUM(wr.wr_net_loss) AS return_loss
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, i.i_category
),
sales_combined AS (
 SELECT * FROM store_sales_agg
 UNION ALL
 SELECT * FROM catalog_sales_agg
 UNION ALL
 SELECT * FROM web_sales_agg
),
returns_combined AS (
 SELECT * FROM store_returns_agg
 UNION ALL
 SELECT * FROM catalog_returns_agg
 UNION ALL
 SELECT * FROM web_returns_agg
),
sales_with_returns AS (
 SELECT
  s.d_year,
  s.i_category,
  s.channel,
  s.net_profit,
  s.quantity_sold,
  s.total_sales,
  s.total_discount,
  s.orders,
  COALESCE(r.return_quantity, 0) AS return_quantity,
  COALESCE(r.return_amount, 0) AS return_amount,
  COALESCE(r.return_loss, 0) AS return_loss,
  CASE WHEN s.total_sales > 0 THEN round(s.total_discount / s.total_sales * 100, 2) ELSE 0 END AS discount_percent,
  CASE WHEN s.quantity_sold > 0 THEN round(COALESCE(r.return_quantity, 0) * 100.0 / s.quantity_sold, 2) ELSE 0 END AS return_rate_percent,
  round(s.net_profit - COALESCE(r.return_loss, 0), 2) AS net_profit_after_returns
 FROM sales_combined s
 LEFT JOIN returns_combined r
   ON s.d_year = r.d_year
  AND s.i_category = r.i_category
  AND s.channel = r.channel
),
final_ranking AS (
 SELECT
  *,
  row_number() OVER (PARTITION BY d_year, channel ORDER BY net_profit_after_returns DESC) AS rank_in_channel_year
 FROM sales_with_returns
)
SELECT
 d_year,
 i_category,
 channel,
 net_profit,
 quantity_sold,
 total_sales,
 total_discount,
 orders,
 return_quantity,
 return_amount,
 return_loss,
 discount_percent,
 return_rate_percent,
 net_profit_after_returns,
 rank_in_channel_year
FROM final_ranking
WHERE rank_in_channel_year <= 10
ORDER BY d_year DESC, channel, rank_in_channel_year
