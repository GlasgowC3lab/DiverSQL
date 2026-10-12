WITH weekend_returns AS (
   SELECT r.r_reason_desc,
          SUM(sr.sr_return_amt) AS total_return,
          'Weekend' AS period_type
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_weekend = 'Y'
   GROUP BY r.r_reason_desc
),
weekday_returns AS (
   SELECT r.r_reason_desc,
          SUM(sr.sr_return_amt) AS total_return,
          'Weekday' AS period_type
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_weekend = 'N'
   GROUP BY r.r_reason_desc
),
combined AS (
   SELECT r_reason_desc, total_return, period_type FROM weekend_returns
   UNION ALL
   SELECT r_reason_desc, total_return, period_type FROM weekday_returns
)
SELECT c.r_reason_desc,
       c.total_return,
       c.period_type
FROM combined c
WHERE c.r_reason_desc NOT IN (
    SELECT r.r_reason_desc
    FROM reason r
    WHERE r.r_reason_desc LIKE '%price%'
)
ORDER BY c.total_return DESC
LIMIT 100
