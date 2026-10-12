WITH s_sales AS (
 SELECT 
   ss.ss_customer_sk AS customer_sk,
   ss.ss_sold_date_sk AS date_sk,
   ss.ss_ticket_number AS order_number,
   ss.ss_net_paid AS net_paid,
   ss.ss_net_profit AS net_profit,
   ss.ss_quantity AS quantity,
   'store' AS channel
 FROM store_sales ss
),
c_sales AS (
 SELECT 
   cs.cs_bill_customer_sk AS customer_sk,
   cs.cs_sold_date_sk AS date_sk,
   cs.cs_order_number AS order_number,
   cs.cs_net_paid AS net_paid,
   cs.cs_net_profit AS net_profit,
   cs.cs_quantity AS quantity,
   'catalog' AS channel
 FROM catalog_sales cs
),
w_sales AS (
 SELECT 
   ws.ws_bill_customer_sk AS customer_sk,
   ws.ws_sold_date_sk AS date_sk,
   ws.ws_order_number AS order_number,
   ws.ws_net_paid AS net_paid,
   ws.ws_net_profit AS net_profit,
   ws.ws_quantity AS quantity,
   'web' AS channel
 FROM web_sales ws
),
sales_union AS (
 SELECT * FROM s_sales
 UNION ALL
 SELECT * FROM c_sales
 UNION ALL
 SELECT * FROM w_sales
),
returns_union AS (
 SELECT
   sr.sr_customer_sk AS customer_sk,
   sr.sr_returned_date_sk AS date_sk,
   sr.sr_ticket_number AS order_number,
   sr.sr_return_amt AS return_amount,
   sr.sr_return_tax AS return_tax,
   sr.sr_net_loss AS net_loss,
   'store' AS channel
 FROM store_returns sr
 UNION ALL
 SELECT
   cr.cr_returning_customer_sk AS customer_sk,
   cr.cr_returned_date_sk AS date_sk,
   cr.cr_order_number AS order_number,
   cr.cr_return_amount AS return_amount,
   cr.cr_return_tax AS return_tax,
   cr.cr_net_loss AS net_loss,
   'catalog' AS channel
 FROM catalog_returns cr
 UNION ALL
 SELECT
   wr.wr_returning_customer_sk AS customer_sk,
   wr.wr_returned_date_sk AS date_sk,
   wr.wr_order_number AS order_number,
   wr.wr_return_amt AS return_amount,
   wr.wr_return_tax AS return_tax,
   wr.wr_net_loss AS net_loss,
   'web' AS channel
 FROM web_returns wr
),
aggregated_sales AS (
 SELECT
   su.customer_sk,
   d.d_year,
   su.channel,
   COUNT(DISTINCT su.order_number) AS orders,
   SUM(su.net_paid) AS total_net_paid,
   SUM(su.net_profit) AS total_net_profit,
   SUM(su.quantity) AS total_quantity,
   COALESCE(SUM(r.return_amount), 0) AS total_return_amount,
   COALESCE(SUM(r.return_tax), 0) AS total_return_tax,
   COALESCE(SUM(r.net_loss), 0) AS total_return_loss
 FROM sales_union su
 LEFT JOIN returns_union r
   ON su.customer_sk = r.customer_sk
   AND su.order_number = r.order_number
   AND su.channel = r.channel
 LEFT JOIN date_dim d
   ON su.date_sk = d.d_date_sk
 GROUP BY su.customer_sk, d.d_year, su.channel
),
ranked_sales AS (
 SELECT
   a.*,
   ROW_NUMBER() OVER (PARTITION BY a.channel ORDER BY a.total_net_paid DESC) AS channel_rank
 FROM aggregated_sales a
),
top_customers AS (
 SELECT *
 FROM ranked_sales
 WHERE channel_rank <= 10
),
final AS (
 SELECT
   tc.customer_sk,
   c.c_customer_id,
   c.c_first_name || ' ' || c.c_last_name AS customer_name,
   tc.d_year,
   tc.channel,
   tc.orders,
   tc.total_net_paid,
   tc.total_net_profit,
   tc.total_quantity,
   tc.total_return_amount,
   tc.total_return_tax,
   tc.total_return_loss,
   CASE WHEN (tc.total_net_paid - tc.total_return_amount) > 0 THEN (tc.total_net_paid - tc.total_return_amount) * 0.9 ELSE 0.0 END AS adjusted_net,
   CASE WHEN tc.total_net_profit IS NULL THEN 'UNKNOWN' ELSE CAST(tc.total_net_profit AS VARCHAR) END AS net_profit_str,
   (SELECT AVG(cs.total_net_profit) FROM aggregated_sales cs WHERE cs.d_year = tc.d_year AND cs.channel = tc.channel) AS avg_channel_net_profit,
   CASE WHEN (tc.total_net_paid - tc.total_return_amount) > (SELECT AVG(cs.total_net_paid) FROM aggregated_sales cs WHERE cs.d_year = tc.d_year AND cs.channel = tc.channel) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS performance_flag
 FROM top_customers tc
 LEFT JOIN customer c
   ON tc.customer_sk = c.c_customer_sk
)
SELECT *
FROM final
WHERE adjusted_net IS NOT NULL
ORDER BY d_year DESC, channel, adjusted_net DESC
LIMIT 100
