WITH refunds AS (
    SELECT c.c_customer_id AS customer_id,
           COUNT(DISTINCT wr.wr_reason_sk) AS distinct_reason_cnt,
           SUM(DISTINCT wr.wr_return_amt) AS sum_return_amt
    FROM customer c
    JOIN web_returns wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IN (1, 3, 5)
      AND wr.wr_reason_sk IN (1, 19, 37)
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_returning_customer_sk = c.c_customer_sk
            AND wr2.wr_return_quantity > 0
      )
    GROUP BY c.c_customer_id
),
returns AS (
    SELECT c.c_customer_id AS customer_id,
           COUNT(DISTINCT wr.wr_reason_sk) AS distinct_reason_cnt,
           SUM(DISTINCT wr.wr_return_amt) AS sum_return_amt
    FROM customer c
    JOIN web_returns wr
      ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IN (2, 7)
      AND wr.wr_reason_sk IN (18, 61)
      AND EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
            AND wr2.wr_return_amt > 50
      )
    GROUP BY c.c_customer_id
)
SELECT u.customer_id,
       u.distinct_reason_cnt,
       u.sum_return_amt
FROM (
    SELECT * FROM refunds
    UNION
    SELECT * FROM returns
) u
ORDER BY u.sum_return_amt DESC
LIMIT 100
