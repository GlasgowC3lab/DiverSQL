WITH union_sales AS (
   SELECT
       ss.ss_sold_date_sk AS sold_date_sk,
       d.d_year,
       CAST(ss.ss_store_sk AS VARCHAR) AS channel_sk,
       s.s_store_name AS channel_name,
       ss.ss_customer_sk AS customer_sk,
       c.c_first_name,
       c.c_last_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(DISTINCT ss.ss_ticket_number) AS tx_count,
       ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS channel_rank,
       'Store' AS channel_type
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2002
   GROUP BY ss.ss_sold_date_sk, d.d_year, ss.ss_store_sk, s.s_store_name, ss.ss_customer_sk, c.c_first_name, c.c_last_name

   UNION ALL

   SELECT
       cs.cs_sold_date_sk AS sold_date_sk,
       d.d_year,
       CAST(cs.cs_call_center_sk AS VARCHAR) AS channel_sk,
       cc.cc_name AS channel_name,
       cs.cs_bill_customer_sk AS customer_sk,
       c.c_first_name,
       c.c_last_name,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(DISTINCT cs.cs_order_number) AS tx_count,
       RANK() OVER (PARTITION BY cs.cs_call_center_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS channel_rank,
       'Catalog' AS channel_type
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2002
   GROUP BY cs.cs_sold_date_sk, d.d_year, cs.cs_call_center_sk, cc.cc_name, cs.cs_bill_customer_sk, c.c_first_name, c.c_last_name

   UNION ALL

   SELECT
       ws.ws_sold_date_sk AS sold_date_sk,
       d.d_year,
       CAST(ws.ws_web_page_sk AS VARCHAR) AS channel_sk,
       wp.wp_type AS channel_name,
       ws.ws_bill_customer_sk AS customer_sk,
       c.c_first_name,
       c.c_last_name,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(DISTINCT ws.ws_order_number) AS tx_count,
       DENSE_RANK() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS channel_rank,
       'Web' AS channel_type
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2002
   GROUP BY ws.ws_sold_date_sk, d.d_year, ws.ws_web_page_sk, wp.wp_type, ws.ws_bill_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
   SELECT
       us.customer_sk,
       SUM(us.total_sales) AS total_sales,
       SUM(us.total_profit) AS total_profit,
       MIN(us.channel_rank) AS best_channel_rank,
       COUNT(DISTINCT us.channel_type) AS channel_count,
       ROW_NUMBER() OVER (ORDER BY SUM(us.total_sales) DESC) AS overall_rank,
       CASE WHEN SUM(us.total_profit) < 0 THEN 'Loss' ELSE 'Profit' END AS profit_status,
       COALESCE(c.c_email_address, 'unknown@example.com') AS email,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       c.c_current_cdemo_sk
   FROM union_sales us
   LEFT JOIN customer c ON us.customer_sk = c.c_customer_sk
   WHERE EXISTS (
       SELECT 1
       FROM customer_demographics cd
       WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
         AND cd.cd_gender = 'M'
   )
   GROUP BY us.customer_sk, c.c_email_address, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
   HAVING SUM(us.total_sales) > 10000
)
SELECT
   tc.overall_rank,
   tc.full_name,
   tc.email,
   tc.profit_status,
   tc.total_sales,
   tc.total_profit,
   CASE WHEN tc.total_sales > (SELECT AVG(total_sales) FROM top_customers) THEN 'Above Avg' ELSE 'Below Avg' END AS sales_category,
   COALESCE(srt.sr_return_quantity, 0) AS store_return_qty,
   COALESCE(crt.cr_return_quantity, 0) AS catalog_return_qty,
   COALESCE(wrt.wr_return_quantity, 0) AS web_return_qty,
   tc.total_sales - (COALESCE(srt.sr_return_quantity,0) * 20 + COALESCE(crt.cr_return_quantity,0) * 25 + COALESCE(wrt.wr_return_quantity,0) * 30) AS net_sales_adj,
   (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = tc.customer_sk) AS total_store_tx,
   (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_bill_customer_sk = tc.customer_sk) AS total_catalog_tx,
   (SELECT COUNT(*) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = tc.customer_sk) AS total_web_tx
FROM top_customers tc
LEFT JOIN (
   SELECT sr_customer_sk, SUM(sr_return_quantity) AS sr_return_quantity
   FROM store_returns
   GROUP BY sr_customer_sk
) srt ON tc.customer_sk = srt.sr_customer_sk
LEFT JOIN (
   SELECT cr_returning_customer_sk, SUM(cr_return_quantity) AS cr_return_quantity
   FROM catalog_returns
   GROUP BY cr_returning_customer_sk
) crt ON tc.customer_sk = crt.cr_returning_customer_sk
LEFT JOIN (
   SELECT wr_returning_customer_sk, SUM(wr_return_quantity) AS wr_return_quantity
   FROM web_returns
   GROUP BY wr_returning_customer_sk
) wrt ON tc.customer_sk = wrt.wr_returning_customer_sk
WHERE tc.overall_rank <= 10
ORDER BY tc.overall_rank
