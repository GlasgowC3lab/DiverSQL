SELECT
    sm.sm_type,
    td.t_hour,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_return_amount) AS total_return_amount,
    CASE
        WHEN SUM(cr.cr_return_amount) = 0 THEN NULL
        ELSE CAST(SUM(cr.cr_refunded_cash) AS double) / SUM(cr.cr_return_amount)
    END AS refund_ratio,
    DENSE_RANK() OVER (
        ORDER BY CASE
            WHEN SUM(cr.cr_return_amount) = 0 THEN 0
            ELSE CAST(SUM(cr.cr_refunded_cash) AS double) / SUM(cr.cr_return_amount)
        END DESC
    ) AS ratio_rank,
    CASE
        WHEN hd_ret.hd_dep_count >= 3 THEN 'Large Household'
        ELSE 'Small Household'
    END AS returning_household_category,
    CASE
        WHEN hd_ref.hd_dep_count >= 3 THEN 'Large Refunded Household'
        ELSE 'Small Refunded Household'
    END AS refunded_household_category
FROM catalog_returns cr
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
GROUP BY
    sm.sm_type,
    td.t_hour,
    hd_ret.hd_buy_potential,
    hd_ref.hd_buy_potential,
    hd_ret.hd_dep_count,
    hd_ref.hd_dep_count
HAVING SUM(cr.cr_refunded_cash) > 0
ORDER BY ratio_rank
LIMIT 10
