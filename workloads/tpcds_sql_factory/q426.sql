WITH reason_sums AS (
    SELECT
        cc.cc_state,
        cc.cc_employees,
        cr.cr_reason_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_meal_time = 'Dinner'
    GROUP BY
        cc.cc_state,
        cc.cc_employees,
        cr.cr_reason_sk
)
SELECT
    rs.cc_state,
    rs.cr_reason_sk,
    rs.total_return_amount,
    rs.total_return_tax,
    RANK() OVER (PARTITION BY rs.cc_state ORDER BY rs.total_return_amount DESC) AS reason_rank,
    PERCENT_RANK() OVER (PARTITION BY rs.cc_state ORDER BY rs.total_return_amount DESC) AS pct_rank,
    CASE
        WHEN rs.cc_employees > 500 THEN 'LARGE'
        ELSE 'SMALL'
    END AS size_category
FROM reason_sums rs
WHERE rs.total_return_amount > 0
ORDER BY rs.cc_state, reason_rank
