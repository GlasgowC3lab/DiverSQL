WITH refunded AS (
    SELECT
        'refunded' AS scenario,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 100000
      AND hd.hd_dep_count <= 5
    GROUP BY GROUPING SETS (
        (hd.hd_buy_potential, ib.ib_lower_bound, ib.ib_upper_bound),
        (hd.hd_buy_potential),
        ()
    )
),
returning AS (
    SELECT
        'returning' AS scenario,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 60000
      AND hd.hd_vehicle_count >= 2
    GROUP BY GROUPING SETS (
        (hd.hd_buy_potential, ib.ib_lower_bound, ib.ib_upper_bound),
        (hd.hd_buy_potential),
        ()
    )
),
combined AS (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
)
SELECT
    scenario,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    total_refunded_cash,
    cnt_returns,
    SUM(total_return_amount) OVER (
        PARTITION BY scenario
        ORDER BY COALESCE(ib_lower_bound, -1), hd_buy_potential
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_return_amount
FROM combined
ORDER BY scenario, running_total_return_amount DESC
