WITH
sales_sample AS (
   SELECT *
   FROM store_sales TABLESAMPLE BERNOULLI (10)
),
sales_joined AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_net_paid,
       ss.ss_net_profit,
       s.s_state,
       s.s_division_name,
       p.p_channel_email,
       c.c_customer_sk,
       cd.cd_demo_sk,
       t.t_time_sk
   FROM sales_sample ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
),
web_time AS (
   SELECT
       wr.wr_returned_time_sk,
       t2.t_time_sk AS web_time_sk
   FROM web_returns wr
   JOIN time_dim t2 ON wr.wr_returned_time_sk = t2.t_time_sk
),
store_returns_keys AS (
   SELECT sr_ticket_number FROM store_returns
),
web_returns_keys AS (
   SELECT wr_order_number FROM web_returns
),
common_keys AS (
   SELECT sr_ticket_number AS ticket
   FROM store_returns_keys
   INTERSECT
   SELECT wr_order_number AS ticket
   FROM web_returns_keys
),
union_returns AS (
   SELECT sr.sr_ticket_number AS key_id,
          sr.sr_return_amt AS return_amount,
          r.r_reason_desc AS reason_desc
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   UNION
   SELECT wr.wr_order_number AS key_id,
          wr.wr_return_amt AS return_amount,
          r.r_reason_desc AS reason_desc
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
),
final_join AS (
   SELECT
       sj.s_state,
       sj.s_division_name,
       sj.p_channel_email,
       ur.return_amount,
       ur.reason_desc,
       sj.ss_net_paid,
       sj.ss_net_profit,
       CASE WHEN ck.ticket IS NOT NULL THEN 1 ELSE 0 END AS common_key_flag
   FROM sales_joined sj
   FULL OUTER JOIN union_returns ur
       ON sj.ss_ticket_number = ur.key_id
   LEFT JOIN common_keys ck
       ON sj.ss_ticket_number = ck.ticket
)
SELECT
   s_state,
   s_division_name,
   p_channel_email,
   reason_desc,
   SUM(ss_net_paid) AS total_paid,
   SUM(ss_net_profit) AS total_profit,
   SUM(return_amount) AS total_return_amount,
   SUM(common_key_flag) AS common_key_count
FROM final_join
GROUP BY GROUPING SETS (
   (s_state, s_division_name, p_channel_email, reason_desc),
   (s_state, s_division_name, reason_desc),
   (p_channel_email, reason_desc),
   (reason_desc),
   ()
)
ORDER BY total_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
