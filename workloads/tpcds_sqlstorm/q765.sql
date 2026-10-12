WITH sales AS (
   SELECT cs.cs_order_number AS order_number, cs.cs_sold_date_sk AS date_sk, cs.cs_bill_customer_sk AS cust_sk,
          cs.cs_net_profit AS profit, 'catalog' AS channel
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_ticket_number, ss.ss_sold_date_sk, ss.ss_customer_sk, ss.ss_net_profit, 'store'
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_bill_customer_sk, ws.ws_net_profit, 'web'
   FROM web_sales ws
),
returns AS (
   SELECT cr.cr_order_number AS order_number, cr.cr_returned_date_sk AS date_sk, cr.cr_refunded_customer_sk AS cust_sk,
          -cr.cr_net_loss AS profit, 'catalog' AS channel
   FROM catalog_returns cr
   UNION ALL
   SELECT sr.sr_ticket_number, sr.sr_returned_date_sk, sr.sr_customer_sk, -sr.sr_net_loss, 'store'
   FROM store_returns sr
   UNION ALL
   SELECT wr.wr_order_number, wr.wr_returned_date_sk, wr.wr_refunded_customer_sk, -wr.wr_net_loss, 'web'
   FROM web_returns wr
),
combined AS (
   SELECT order_number, date_sk, cust_sk, profit, channel FROM sales
   UNION ALL
   SELECT order_number, date_sk, cust_sk, profit, channel FROM returns
),
monthly_customer AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       c.c_customer_id,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS cust_name,
       cd.cd_gender AS gender,
       cd.cd_marital_status AS marital_status,
       SUM(comb.profit) AS net_profit,
       COUNT(DISTINCT comb.channel) AS channel_cnt,
       SUM(CASE WHEN comb.channel = 'store' THEN comb.profit ELSE 0 END) AS store_profit,
       SUM(CASE WHEN comb.channel = 'catalog' THEN comb.profit ELSE 0 END) AS catalog_profit,
       SUM(CASE WHEN comb.channel = 'web' THEN comb.profit ELSE 0 END) AS web_profit
   FROM combined comb
   JOIN date_dim d ON comb.date_sk = d.d_date_sk
   JOIN customer c ON comb.cust_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY
       d.d_year,
       d.d_month_seq,
       c.c_customer_id,
       CONCAT(c.c_first_name, ' ', c.c_last_name),
       cd.cd_gender,
       cd.cd_marital_status
)
SELECT
   mc.d_year,
   mc.d_month_seq,
   mc.c_customer_id,
   mc.cust_name,
   mc.gender,
   mc.marital_status,
   mc.net_profit,
   mc.channel_cnt,
   mc.store_profit,
   mc.catalog_profit,
   mc.web_profit,
   RANK() OVER (PARTITION BY mc.d_year ORDER BY mc.net_profit DESC) AS rank_year,
   RANK() OVER (PARTITION BY mc.d_year, mc.d_month_seq ORDER BY mc.net_profit DESC) AS rank_month,
   SUM(mc.net_profit) OVER (PARTITION BY mc.c_customer_id ORDER BY mc.d_year, mc.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit,
   AVG(mc.net_profit) OVER (PARTITION BY mc.c_customer_id ORDER BY mc.d_year, mc.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3mo
FROM monthly_customer mc
WHERE mc.net_profit > 0
ORDER BY mc.d_year, mc.d_month_seq, mc.net_profit DESC
LIMIT 200
