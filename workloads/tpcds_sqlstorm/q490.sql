WITH
store_sales_agg AS (
   SELECT
     ss.ss_customer_sk AS customer_sk,
     c.c_first_name,
     c.c_last_name,
     d.d_year,
     SUM(ss.ss_net_profit) AS store_net_profit,
     SUM(ss.ss_net_paid) AS store_net_paid,
     SUM(ss.ss_quantity) AS store_quantity,
     COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
     SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_loss,
     COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count
   FROM store_sales ss
   LEFT JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk = sr.sr_item_sk
     AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
   GROUP BY ss.ss_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
catalog_sales_agg AS (
   SELECT
     cs.cs_bill_customer_sk AS customer_sk,
     c.c_first_name,
     c.c_last_name,
     d.d_year,
     SUM(cs.cs_net_profit) AS catalog_net_profit,
     SUM(cs.cs_net_paid) AS catalog_net_paid,
     SUM(cs.cs_quantity) AS catalog_quantity,
     COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
     SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_return_loss,
     COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count
   FROM catalog_sales cs
   LEFT JOIN catalog_returns cr
     ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_item_sk = cr.cr_item_sk
     AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
   GROUP BY cs.cs_bill_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
web_sales_agg AS (
   SELECT
     ws.ws_bill_customer_sk AS customer_sk,
     c.c_first_name,
     c.c_last_name,
     d.d_year,
     SUM(ws.ws_net_profit) AS web_net_profit,
     SUM(ws.ws_net_paid) AS web_net_paid,
     SUM(ws.ws_quantity) AS web_quantity,
     COUNT(DISTINCT ws.ws_order_number) AS web_orders,
     SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_loss,
     COUNT(DISTINCT wr.wr_order_number) AS web_return_count
   FROM web_sales ws
   LEFT JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
     AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
   GROUP BY ws.ws_bill_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
combined_sales AS (
   SELECT
     COALESCE(s.customer_sk, c.customer_sk, w.customer_sk) AS customer_sk,
     COALESCE(s.c_first_name, c.c_first_name, w.c_first_name) AS first_name,
     COALESCE(s.c_last_name, c.c_last_name, w.c_last_name) AS last_name,
     COALESCE(s.d_year, c.d_year, w.d_year) AS year,
     COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
     COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0) AS total_net_paid,
     COALESCE(s.store_quantity, 0) + COALESCE(c.catalog_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
     COALESCE(s.store_orders, 0) + COALESCE(c.catalog_orders, 0) + COALESCE(w.web_orders, 0) AS total_orders,
     COALESCE(s.store_return_loss, 0) + COALESCE(c.catalog_return_loss, 0) + COALESCE(w.web_return_loss, 0) AS total_return_loss,
     COALESCE(s.store_return_count, 0) + COALESCE(c.catalog_return_count, 0) + COALESCE(w.web_return_count, 0) AS total_return_count
   FROM store_sales_agg s
   FULL OUTER JOIN catalog_sales_agg c
     ON s.customer_sk = c.customer_sk
   FULL OUTER JOIN web_sales_agg w
     ON COALESCE(s.customer_sk, c.customer_sk) = w.customer_sk
),
customer_with_demo AS (
   SELECT
     cs.*,
     cust.c_current_cdemo_sk,
     d.cd_gender,
     d.cd_credit_rating,
     d.cd_marital_status,
     d.cd_education_status,
     d.cd_dep_count,
     d.cd_dep_employed_count,
     d.cd_dep_college_count
   FROM combined_sales cs
   LEFT JOIN customer cust
     ON cs.customer_sk = cust.c_customer_sk
   LEFT JOIN customer_demographics d
     ON cust.c_current_cdemo_sk = d.cd_demo_sk
),
customer_detail AS (
   SELECT
     cwd.customer_sk,
     cwd.first_name,
     cwd.last_name,
     cwd.year,
     cwd.total_net_profit,
     cwd.total_net_paid,
     cwd.total_quantity,
     cwd.total_orders,
     cwd.total_return_loss,
     cwd.total_return_count,
     cwd.cd_gender,
     cwd.cd_credit_rating,
     CONCAT(COALESCE(cwd.first_name, ''), ' ', COALESCE(cwd.last_name, '')) AS full_name,
     CASE
       WHEN cwd.total_net_profit > 0 THEN 'PROFITABLE'
       WHEN cwd.total_net_profit < 0 THEN 'LOSS'
       ELSE 'NEUTRAL'
     END AS profit_category,
     ROW_NUMBER() OVER (PARTITION BY cwd.cd_gender ORDER BY cwd.total_net_profit DESC) AS gender_rank,
     SUM(cwd.total_net_profit) OVER (PARTITION BY cwd.cd_credit_rating) AS credit_rating_total_profit
   FROM customer_with_demo cwd
   WHERE cwd.total_net_profit IS NOT NULL
),
filtered_customers AS (
   SELECT *
   FROM customer_detail cd
   WHERE cd.credit_rating_total_profit > (SELECT AVG(credit_rating_total_profit) FROM customer_detail)
     AND (cd.total_quantity > 0 OR cd.total_return_count > 0)
)
SELECT
   cd.customer_sk,
   cd.first_name,
   cd.last_name,
   cd.year,
   cd.total_net_profit,
   cd.total_net_paid,
   cd.total_quantity,
   cd.total_orders,
   cd.total_return_loss,
   cd.total_return_count,
   cd.cd_gender,
   cd.cd_credit_rating,
   cd.full_name,
   cd.profit_category,
   cd.gender_rank,
   cd.credit_rating_total_profit,
   CASE WHEN cd.gender_rank <= 5 THEN 'TOP5' ELSE 'OTHERS' END AS tier,
   CASE WHEN cd.full_name IS NULL OR TRIM(cd.full_name) = '' THEN 'UNKNOWN' ELSE cd.full_name END AS display_name,
   cd.total_return_loss / NULLIF(cd.total_return_count, 0) AS avg_return_loss_per_return,
   (SELECT AVG(total_net_profit) FROM customer_detail WHERE cd_gender = cd.cd_gender) AS avg_gender_profit,
   (SELECT COUNT(*) FROM customer_detail cd2 WHERE cd2.total_net_profit > cd.total_net_profit) AS customers_with_higher_profit
FROM filtered_customers cd
UNION ALL
SELECT
   NULL AS customer_sk,
   NULL AS first_name,
   NULL AS last_name,
   2001 AS year,
   SUM(total_net_profit) AS total_net_profit,
   SUM(total_net_paid) AS total_net_paid,
   SUM(total_quantity) AS total_quantity,
   SUM(total_orders) AS total_orders,
   SUM(total_return_loss) AS total_return_loss,
   SUM(total_return_count) AS total_return_count,
   NULL AS cd_gender,
   NULL AS cd_credit_rating,
   'ALL_CUSTOMERS' AS full_name,
   'NEUTRAL' AS profit_category,
   NULL AS gender_rank,
   SUM(total_net_profit) AS credit_rating_total_profit,
   'TOTAL' AS tier,
   'ALL_CUSTOMERS' AS display_name,
   CASE WHEN SUM(total_return_count) = 0 THEN NULL ELSE SUM(total_return_loss) / SUM(total_return_count) END AS avg_return_loss_per_return,
   NULL AS avg_gender_profit,
   NULL AS customers_with_higher_profit
FROM filtered_customers
