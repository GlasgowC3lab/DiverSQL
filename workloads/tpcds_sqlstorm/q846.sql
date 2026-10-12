WITH unified_sales AS (
 SELECT
   d.d_year,
   d.d_month_seq,
   'Catalog' AS channel,
   COALESCE(cc.cc_state, w.w_state, ca.ca_state) AS region,
   cs.cs_order_number AS order_number,
   cs.cs_quantity AS quantity,
   cs.cs_net_paid_inc_tax AS sales_amount,
   cs.cs_net_profit AS profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
 LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk

 UNION ALL

 SELECT
   d.d_year,
   d.d_month_seq,
   'Catalog' AS channel,
   COALESCE(cc.cc_state, w.w_state, ca.ca_state) AS region,
   cr.cr_order_number AS order_number,
   -cr.cr_return_quantity AS quantity,
   -cr.cr_return_amount AS sales_amount,
   -cr.cr_net_loss AS profit
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
 LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk

 UNION ALL

 SELECT
   d.d_year,
   d.d_month_seq,
   'Web' AS channel,
   ca.ca_state AS region,
   ws.ws_order_number AS order_number,
   ws.ws_quantity AS quantity,
   ws.ws_net_paid_inc_tax AS sales_amount,
   ws.ws_net_profit AS profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk

 UNION ALL

 SELECT
   d.d_year,
   d.d_month_seq,
   'Web' AS channel,
   ca.ca_state AS region,
   wr.wr_order_number AS order_number,
   -wr.wr_return_quantity AS quantity,
   -wr.wr_return_amt AS sales_amount,
   -wr.wr_net_loss AS profit
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 LEFT JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk

 UNION ALL

 SELECT
   d.d_year,
   d.d_month_seq,
   'Store' AS channel,
   COALESCE(st.s_state, ca.ca_state) AS region,
   ss.ss_ticket_number AS order_number,
   ss.ss_quantity AS quantity,
   ss.ss_net_paid_inc_tax AS sales_amount,
   ss.ss_net_profit AS profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 LEFT JOIN store st ON ss.ss_store_sk = st.s_store_sk
 LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk

 UNION ALL

 SELECT
   d.d_year,
   d.d_month_seq,
   'Store' AS channel,
   COALESCE(st.s_state, ca.ca_state) AS region,
   sr.sr_ticket_number AS order_number,
   -sr.sr_return_quantity AS quantity,
   -sr.sr_return_amt AS sales_amount,
   -sr.sr_net_loss AS profit
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 LEFT JOIN store st ON sr.sr_store_sk = st.s_store_sk
 LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),
aggregated AS (
 SELECT
   d_year,
   d_month_seq,
   channel,
   region,
   SUM(sales_amount) AS total_sales_amount,
   SUM(profit) AS total_profit,
   SUM(quantity) AS total_quantity,
   COUNT(DISTINCT order_number) AS distinct_orders,
   -SUM(CASE WHEN sales_amount < 0 THEN sales_amount ELSE 0 END) AS total_return_amount,
   approx_percentile(sales_amount, 0.5) AS median_sales_amount,
   MAX(CASE WHEN sales_amount > 0 THEN sales_amount END) AS max_sale_amount,
   MIN(CASE WHEN sales_amount > 0 THEN sales_amount END) AS min_sale_amount,
   AVG(sales_amount) AS avg_sale_amount
 FROM unified_sales
 WHERE d_year BETWEEN 2000 AND 2002
 GROUP BY GROUPING SETS (
   (d_year, d_month_seq, channel, region),
   (d_year, channel, region),
   (channel, region),
   (channel)
 )
 HAVING SUM(sales_amount) > 0
)
SELECT
   d_year,
   d_month_seq,
   channel,
   region,
   total_sales_amount,
   total_profit,
   total_quantity,
   distinct_orders,
   total_return_amount,
   median_sales_amount,
   max_sale_amount,
   min_sale_amount,
   avg_sale_amount,
   ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales_amount DESC) AS channel_sales_rank
FROM aggregated
ORDER BY total_sales_amount DESC
LIMIT 100
