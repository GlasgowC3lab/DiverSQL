WITH joined_data AS (
    SELECT
        td.t_meal_time,
        cd.cd_gender,
        r.r_reason_desc,
        sr.sr_return_amt,
        cr.cr_return_amount
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    WHERE td.t_meal_time = 'dinner'
      AND sr.sr_return_quantity > 10
      AND r.r_reason_desc LIKE '%damaged%'
),
agg AS (
    SELECT
        t_meal_time,
        cd_gender,
        r_reason_desc,
        SUM(COALESCE(sr_return_amt, 0) + COALESCE(cr_return_amount, 0)) AS total_return_amt,
        COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY t_meal_time, cd_gender, r_reason_desc
)
SELECT *
FROM (
    SELECT
        t_meal_time,
        cd_gender,
        r_reason_desc,
        total_return_amt,
        txn_count,
        AVG(total_return_amt) OVER (PARTITION BY t_meal_time) AS avg_return_amt_meal,
        SUM(total_return_amt) OVER (
            PARTITION BY t_meal_time
            ORDER BY total_return_amt DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_return,
        ROW_NUMBER() OVER (PARTITION BY t_meal_time ORDER BY total_return_amt DESC) AS rank_in_meal
    FROM agg
    WHERE total_return_amt > 1000
) sub
WHERE rank_in_meal <= 3
ORDER BY t_meal_time, rank_in_meal
LIMIT 100
