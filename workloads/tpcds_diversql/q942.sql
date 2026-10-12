WITH sampled_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
    WHERE wr_return_quantity > 0                 -- predicate 1
      AND wr_return_amt > 10                     -- predicate 2
      AND wr_returned_time_sk IS NOT NULL        -- predicate 3
      AND wr_reason_sk IS NOT NULL               -- predicate 4
      AND wr_order_number BETWEEN 5 AND 30       -- predicate 5
      AND wr_reversed_charge < 400               -- predicate 6
),
joined AS (
    SELECT
        sr.wr_order_number,
        sr.wr_return_amt,
        sr.wr_return_tax,
        sr.wr_return_quantity,
        r.r_reason_desc,
        t.t_meal_time,
        t.t_hour,
        t.t_minute,
        CASE
            WHEN sr.wr_return_amt_inc_tax > 100 THEN 'HIGH'
            ELSE 'LOW'
        END AS amt_category
    FROM sampled_returns sr
    JOIN reason r ON sr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_meal_time IN ('breakfast','lunch','dinner')           -- predicate 7
      AND t.t_hour BETWEEN 7 AND 20                               -- predicate 8
      AND t.t_second <> 0                                          -- predicate 9
      AND r.r_reason_id LIKE 'AAAAAAA%'                           -- predicate 10
),
agg1 AS (
    SELECT
        amt_category,
        r_reason_desc,
        SUM(wr_return_amt)        AS total_return_amt,
        SUM(wr_return_quantity)   AS total_qty,
        COUNT(DISTINCT wr_order_number) AS order_cnt
    FROM joined
    GROUP BY amt_category, r_reason_desc
    HAVING SUM(wr_return_amt) > 500
),
agg2 AS (
    SELECT
        amt_category,
        AVG(total_return_amt) AS avg_total_return_amt
    FROM agg1
    GROUP BY amt_category
),
sub1 AS (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_returned_time_sk IN (
        SELECT t_time_sk FROM time_dim WHERE t_meal_time = 'breakfast'
    )
      AND wr_reason_sk = 12
),
sub2 AS (
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_returned_time_sk IN (
        SELECT t_time_sk FROM time_dim WHERE t_meal_time = 'lunch'
    )
      AND wr_reason_sk = 20
),
intersect_set AS (
    SELECT wr_order_number FROM sub1
    INTERSECT
    SELECT wr_order_number FROM sub2
),
union_set AS (
    SELECT wr_order_number FROM sub1
    UNION
    SELECT wr_order_number FROM sub2
),
except_set AS (
    SELECT wr_order_number FROM sub1
    EXCEPT
    SELECT wr_order_number FROM sub2
)
SELECT
    a2.amt_category,
    a2.avg_total_return_amt,
    ic.cnt_intersect,
    uc.cnt_union,
    ec.cnt_except
FROM agg2 a2
LEFT JOIN (SELECT COUNT(*) AS cnt_intersect FROM intersect_set) ic ON TRUE
LEFT JOIN (SELECT COUNT(*) AS cnt_union      FROM union_set)      uc ON TRUE
LEFT JOIN (SELECT COUNT(*) AS cnt_except    FROM except_set)    ec ON TRUE
ORDER BY a2.avg_total_return_amt DESC
LIMIT 100
