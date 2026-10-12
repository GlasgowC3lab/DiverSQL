WITH
   cs_part AS (
       SELECT
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_net_paid        AS amount,
           t.t_shift             AS shift
       FROM catalog_sales cs
       JOIN customer c      ON cs.cs_bill_customer_sk = c.c_customer_sk
       JOIN time_dim t      ON cs.cs_sold_time_sk = t.t_time_sk
       WHERE t.t_shift = 'first'
   ),
   fr_part AS (
       SELECT
           sr.sr_customer_sk AS customer_sk,
           sr.sr_return_amt  AS amount,
           td.t_shift        AS shift
       FROM store_returns sr
       FULL OUTER JOIN time_dim td
           ON sr.sr_return_time_sk = td.t_time_sk
   ),
   union_set AS (
       SELECT customer_sk, amount, shift FROM cs_part
       UNION
       SELECT customer_sk, amount, shift FROM fr_part
   ),
   intersect_set AS (
       SELECT cs.cs_bill_customer_sk AS customer_sk FROM catalog_sales cs
       INTERSECT
       SELECT ws.ws_bill_customer_sk          FROM web_sales ws
   ),
   ranked AS (
       SELECT
           u.customer_sk,
           u.amount,
           u.shift,
           ROW_NUMBER() OVER (ORDER BY u.amount DESC)                         AS rn_global,
           ROW_NUMBER() OVER (PARTITION BY u.shift ORDER BY u.amount DESC)      AS rn_shift
       FROM union_set u
   )
SELECT
    r.customer_sk,
    r.amount,
    r.shift,
    r.rn_global,
    r.rn_shift,
    CASE WHEN i.customer_sk IS NOT NULL THEN 1 ELSE 0 END AS in_both_channels
FROM ranked r
LEFT JOIN intersect_set i ON r.customer_sk = i.customer_sk
WHERE r.rn_shift <= 5
ORDER BY r.amount DESC
LIMIT 100
