WITH filtered_returns AS (
   SELECT
       wr.wr_returning_customer_sk,
       wr.wr_refunded_customer_sk,
       wr.wr_reason_sk,
       wr.wr_returned_time_sk,
       wr.wr_net_loss,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       c_ret.c_first_name,
       c_ret.c_last_name,
       r.r_reason_desc,
       t.t_hour
   FROM web_returns AS wr
   JOIN reason AS r
       ON wr.wr_reason_sk = r.r_reason_sk
   JOIN time_dim AS t
       ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN customer AS c_ref
       ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
   JOIN customer AS c_ret
       ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
   WHERE r.r_reason_desc LIKE '%damaged%'
     AND t.t_hour BETWEEN 8 AND 18
     AND c_ret.c_birth_month IN (1, 5, 9)
),
agg AS (
   SELECT
       fr.wr_returning_customer_sk,
       fr.c_first_name,
       fr.c_last_name,
       fr.r_reason_desc,
       SUM(fr.wr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt,
       ROW_NUMBER() OVER (PARTITION BY fr.r_reason_desc ORDER BY SUM(fr.wr_net_loss) DESC) AS rn_reason
   FROM filtered_returns AS fr
   GROUP BY
       fr.wr_returning_customer_sk,
       fr.c_first_name,
       fr.c_last_name,
       fr.r_reason_desc
),
shifts AS (
   SELECT DISTINCT t_shift
   FROM time_dim
   WHERE t_shift IS NOT NULL
   LIMIT 3
)
SELECT
   a.rn_reason,
   a.wr_returning_customer_sk,
   a.c_first_name,
   a.c_last_name,
   a.r_reason_desc,
   a.total_net_loss,
   a.return_cnt,
   s.t_shift
FROM agg AS a
CROSS JOIN shifts AS s
WHERE a.rn_reason <= 10
ORDER BY a.total_net_loss DESC, s.t_shift
LIMIT 100
