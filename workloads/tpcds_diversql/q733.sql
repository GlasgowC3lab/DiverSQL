WITH sampled_hd AS (
    SELECT *
    FROM household_demographics
    TABLESAMPLE BERNOULLI (20)
),
joined AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM sampled_hd hd
    FULL OUTER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count IS NOT NULL AND hd.hd_dep_count >= 0
      AND hd.hd_vehicle_count IS NOT NULL AND hd.hd_vehicle_count BETWEEN 0 AND 5
      AND hd.hd_buy_potential LIKE '%-%'
      AND ib.ib_upper_bound IS NOT NULL AND ib.ib_upper_bound <= 150000
      AND ib.ib_lower_bound IS NOT NULL AND ib.ib_lower_bound >= 10000
),
exploded AS (
    SELECT
        j.hd_demo_sk,
        j.hd_income_band_sk,
        j.hd_buy_potential,
        j.ib_lower_bound,
        j.ib_upper_bound,
        CASE
            WHEN val = j.hd_dep_count THEN 'dep'
            WHEN val = j.hd_vehicle_count THEN 'vehicle'
            ELSE 'other'
        END AS metric_type,
        val AS metric_value
    FROM joined j
    CROSS JOIN UNNEST(ARRAY[j.hd_dep_count, j.hd_vehicle_count]) AS t(val)
),
final AS (
    SELECT
        e.hd_demo_sk,
        e.hd_income_band_sk,
        e.hd_buy_potential,
        e.ib_lower_bound,
        e.ib_upper_bound,
        e.metric_type,
        e.metric_value,
        (
            SELECT COUNT(*)
            FROM income_band ib2
            WHERE ib2.ib_lower_bound = e.ib_lower_bound
        ) AS same_lower_bound_cnt,
        ROW_NUMBER() OVER (PARTITION BY e.metric_type ORDER BY e.metric_value DESC) AS rn_metric_desc,
        RANK() OVER (ORDER BY e.metric_value DESC) AS overall_rank
    FROM exploded e
    WHERE e.metric_value IS NOT NULL
)
SELECT
    hd_demo_sk,
    hd_income_band_sk,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    metric_type,
    metric_value,
    same_lower_bound_cnt,
    rn_metric_desc,
    overall_rank
FROM final
ORDER BY overall_rank ASC, rn_metric_desc ASC
LIMIT 100
