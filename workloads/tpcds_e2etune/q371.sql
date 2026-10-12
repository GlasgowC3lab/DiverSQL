WITH ib_filtered AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        (ib_upper_bound - ib_lower_bound) AS band_width
    FROM income_band
    WHERE ib_income_band_sk BETWEEN 1 AND 5
      AND ib_lower_bound >= 0
),
sm_filtered AS (
    SELECT
        sm_ship_mode_sk,
        sm_ship_mode_id,
        sm_contract,
        sm_type
    FROM ship_mode
    WHERE sm_contract IN ('YvxVaJI10', 'ldhM8IvpzHgdbBgDfI')
),
cross_agg AS (
    SELECT
        ib.ib_income_band_sk,
        sm.sm_ship_mode_id,
        SUM(ib.band_width) AS total_band_width,
        COUNT(*) AS cross_row_cnt,
        AVG(ib.band_width) AS avg_band_width
    FROM ib_filtered ib
    JOIN sm_filtered sm
      ON 1 = 1
    GROUP BY ib.ib_income_band_sk, sm.sm_ship_mode_id
    HAVING COUNT(*) >= 1
)
SELECT
    ib_income_band_sk,
    sm_ship_mode_id,
    total_band_width,
    cross_row_cnt,
    avg_band_width,
    RANK() OVER (ORDER BY total_band_width DESC) AS width_rank,
    ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY ib_income_band_sk) AS row_in_ship_mode
FROM cross_agg
ORDER BY width_rank
LIMIT 15
