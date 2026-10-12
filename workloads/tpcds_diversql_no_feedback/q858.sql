WITH filtered_household AS (
    SELECT
        hd_demo_sk,
        hd_income_band_sk,
        hd_buy_potential,
        hd_dep_count,
        hd_vehicle_count
    FROM household_demographics hd
    WHERE hd.hd_buy_potential LIKE '%-%'
      AND regexp_like(hd.hd_buy_potential, '^\\d{4,5}-\\d{4,5}$')
)
SELECT
    hd.hd_buy_potential,
    MAX(hd.hd_vehicle_count) AS vehicle_count,
    sum(sr.sr_return_amt) AS total_store_return_amt,
    sum(sr.sr_net_loss) AS total_store_net_loss,
    (
        SELECT sum(cr.cr_return_amount)
        FROM catalog_returns cr
        JOIN household_demographics hd_sub
            ON cr.cr_refunded_hdemo_sk = hd_sub.hd_demo_sk
        WHERE hd_sub.hd_buy_potential = hd.hd_buy_potential
    ) AS total_catalog_return_amt_by_potential,
    concat('Potential ', hd.hd_buy_potential) AS potential_label,
    cast(regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 1) AS integer) AS lower_bound,
    cast(regexp_extract(hd.hd_buy_potential, '(\\d+)-(\\d+)', 2) AS integer) AS upper_bound
FROM store_returns sr
JOIN filtered_household hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
GROUP BY
    GROUPING SETS (
        (hd.hd_buy_potential, hd.hd_vehicle_count),
        (hd.hd_buy_potential)
    )
ORDER BY total_store_return_amt DESC
LIMIT 100
