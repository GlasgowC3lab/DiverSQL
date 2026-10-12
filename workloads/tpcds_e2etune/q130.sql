WITH month_day_counts AS (
    SELECT
        d_year,
        d_moy,
        d_weekend,
        COUNT(*) AS day_cnt
    FROM date_dim
    WHERE d_current_month = 'Y'
      AND d_year BETWEEN 2015 AND 2020
    GROUP BY d_year, d_moy, d_weekend
),
band_month_agg AS (
    SELECT
        ib.ib_income_band_sk AS band_id,
        md.d_year,
        md.d_moy AS month_of_year,
        SUM(md.day_cnt) AS total_days,
        SUM(CASE WHEN md.d_weekend = 'Y' THEN md.day_cnt ELSE 0 END) AS weekend_days
    FROM month_day_counts md
    JOIN income_band ib
      ON md.d_moy BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY ib.ib_income_band_sk, md.d_year, md.d_moy
)
SELECT
    band_id,
    d_year,
    month_of_year,
    total_days,
    weekend_days,
    RANK() OVER (PARTITION BY band_id ORDER BY total_days DESC) AS month_rank_in_band
FROM band_month_agg
WHERE total_days > 0
ORDER BY band_id, d_year, month_of_year
