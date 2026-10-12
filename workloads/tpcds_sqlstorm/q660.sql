WITH store_data AS (
 SELECT 
   ss.ss_sold_date_sk AS date_sk,
   ss.ss_store_sk AS channel_sk,
   'store' AS channel,
   s.s_store_name AS channel_name,
   ss.ss_ext_sales_price AS sales_amount,
   ss.ss_net_profit AS profit,
   COALESCE(sr.sr_net_loss, 0) AS return_loss,
   ss.ss_item_sk AS item_sk
 FROM store_sales ss
 LEFT JOIN store_returns sr
   ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
  AND ss.ss_store_sk = sr.sr_store_sk
 JOIN store s
   ON ss.ss_store_sk = s.s_store_sk
),
catalog_data AS (
 SELECT 
   cs.cs_sold_date_sk AS date_sk,
   cs.cs_call_center_sk AS channel_sk,
   'catalog' AS channel,
   cc.cc_name AS channel_name,
   cs.cs_ext_sales_price AS sales_amount,
   cs.cs_net_profit AS profit,
   COALESCE(cr.cr_net_loss, 0) AS return_loss,
   cs.cs_item_sk AS item_sk
 FROM catalog_sales cs
 LEFT JOIN catalog_returns cr
   ON cs.cs_order_number = cr.cr_order_number
  AND cs.cs_item_sk = cr.cr_item_sk
  AND cs.cs_call_center_sk = cr.cr_call_center_sk
 JOIN call_center cc
   ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
web_data AS (
 SELECT 
   ws.ws_sold_date_sk AS date_sk,
   ws.ws_web_page_sk AS channel_sk,
   'web' AS channel,
   wp.wp_url AS channel_name,
   ws.ws_ext_sales_price AS sales_amount,
   ws.ws_net_profit AS profit,
   COALESCE(wr.wr_net_loss, 0) AS return_loss,
   ws.ws_item_sk AS item_sk
 FROM web_sales ws
 LEFT JOIN web_returns wr
   ON ws.ws_order_number = wr.wr_order_number
  AND ws.ws_item_sk = wr.wr_item_sk
  AND ws.ws_web_page_sk = wr.wr_web_page_sk
 JOIN web_page wp
   ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
combined AS (
 SELECT * FROM store_data
 UNION ALL
 SELECT * FROM catalog_data
 UNION ALL
 SELECT * FROM web_data
),
final_agg AS (
 SELECT 
   d.d_year,
   d.d_month_seq,
   c.channel,
   c.channel_name,
   SUM(c.sales_amount) AS total_sales,
   SUM(c.profit) - SUM(c.return_loss) AS net_profit,
   COUNT(DISTINCT c.item_sk) AS distinct_items
 FROM combined c
 JOIN date_dim d ON c.date_sk = d.d_date_sk
 GROUP BY d.d_year, d.d_month_seq, c.channel, c.channel_name
)
SELECT *
FROM final_agg
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
