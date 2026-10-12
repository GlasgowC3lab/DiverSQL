WITH sales_union AS (
   SELECT
       cs.cs_order_number AS order_number,
       cs.cs_sold_date_sk AS date_sk,
       cs.cs_bill_customer_sk AS customer_sk,
       cs.cs_net_paid AS net_paid,
       cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
       cs.cs_net_profit AS net_profit,
       cs.cs_quantity AS quantity,
       'catalog' AS channel
   FROM catalog_sales cs
   UNION ALL
   SELECT
       ss.ss_ticket_number AS order_number,
       ss.ss_sold_date_sk AS date_sk,
       ss.ss_customer_sk AS customer_sk,
       ss.ss_net_paid AS net_paid,
       ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
       ss.ss_net_profit AS net_profit,
       ss.ss_quantity AS quantity,
       'store' AS channel
   FROM store_sales ss
   UNION ALL
   SELECT
       ws.ws_order_number AS order_number,
       ws.ws_sold_date_sk AS date_sk,
       ws.ws_bill_customer_sk AS customer_sk,
       ws.ws_net_paid AS net_paid,
       ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
       ws.ws_net_profit AS net_profit,
       ws.ws_quantity AS quantity,
       'web' AS channel
   FROM web_sales ws
),
returns_union AS (
   SELECT
       cr.cr_order_number AS order_number,
       cr.cr_returned_date_sk AS return_date_sk,
       cr.cr_refunded_customer_sk AS customer_sk,
       cr.cr_return_amount AS return_amount,
       cr.cr_net_loss AS net_loss,
       'catalog' AS channel
   FROM catalog_returns cr
   UNION ALL
   SELECT
       sr.sr_ticket_number AS order_number,
       sr.sr_returned_date_sk AS return_date_sk,
       sr.sr_customer_sk AS customer_sk,
       sr.sr_return_amt AS return_amount,
       sr.sr_net_loss AS net_loss,
       'store' AS channel
   FROM store_returns sr
   UNION ALL
   SELECT
       wr.wr_order_number AS order_number,
       wr.wr_returned_date_sk AS return_date_sk,
       wr.wr_refunded_customer_sk AS customer_sk,
       wr.wr_return_amt AS return_amount,
       wr.wr_net_loss AS net_loss,
       'web' AS channel
   FROM web_returns wr
),
sales_agg AS (
   SELECT
       su.customer_sk,
       su.channel,
       MIN(d.d_year) AS first_year,
       MAX(d.d_year) AS last_year,
       SUM(su.net_paid) AS total_net_paid,
       SUM(su.net_paid_inc_tax) AS total_net_paid_inc_tax,
       SUM(su.net_profit) AS total_net_profit,
       SUM(su.quantity) AS total_quantity,
       COUNT(DISTINCT su.order_number) AS orders_cnt
   FROM sales_union su
   LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
   GROUP BY su.customer_sk, su.channel
),
returns_agg AS (
   SELECT
       ru.customer_sk,
       ru.channel,
       SUM(ru.return_amount) AS total_return_amount,
       SUM(ru.net_loss) AS total_net_loss,
       COUNT(DISTINCT ru.order_number) AS return_orders_cnt
   FROM returns_union ru
   GROUP BY ru.customer_sk, ru.channel
),
customer_info AS (
   SELECT
       c.c_customer_sk,
       COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
       COALESCE(cd.cd_gender, 'U') AS gender,
       ca.ca_country AS country,
       COALESCE(sa.last_year, 0) AS latest_year
   FROM customer c
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN (
       SELECT
           customer_sk,
           MAX(last_year) AS last_year
       FROM sales_agg
       GROUP BY customer_sk
   ) sa ON c.c_customer_sk = sa.customer_sk
),
customer_aggregated AS (
   SELECT
       ci.c_customer_sk,
       ci.full_name,
       ci.gender,
       ci.country,
       ci.latest_year,
       COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0) AS net_profit_adjusted,
       sa.channel,
       ROW_NUMBER() OVER (PARTITION BY ci.c_customer_sk ORDER BY (COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0)) DESC) AS profit_rank,
       (SELECT AVG(total_net_profit) FROM sales_agg WHERE channel = sa.channel) -
       (SELECT AVG(total_net_loss) FROM returns_agg WHERE channel = ra.channel) AS channel_profit_margin_avg
   FROM customer_info ci
   LEFT JOIN sales_agg sa ON ci.c_customer_sk = sa.customer_sk
   LEFT JOIN returns_agg ra ON ci.c_customer_sk = ra.customer_sk AND sa.channel = ra.channel
   WHERE (COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0)) IS NOT NULL
),
final_set AS (
   SELECT
       ca.c_customer_sk,
       ca.full_name,
       ca.gender,
       ca.country,
       ca.latest_year,
       ca.net_profit_adjusted,
       ca.profit_rank,
       ca.channel,
       CASE WHEN ca.profit_rank <= 5 THEN 1 ELSE 0 END AS top_5_flag,
       ca.channel_profit_margin_avg,
       UPPER(REVERSE(ca.full_name)) AS reversed_full_name_upper,
       CASE
           WHEN ca.latest_year >= (SELECT MAX(d_year) FROM date_dim) - 2 THEN 'RECENT'
           ELSE 'OLDER'
       END AS recency_category,
       COALESCE(ca.net_profit_adjusted, 0) AS net_profit_coalesced
   FROM customer_aggregated ca
   WHERE ca.net_profit_adjusted > 0
)
SELECT *
FROM final_set
ORDER BY net_profit_adjusted DESC
LIMIT 100
