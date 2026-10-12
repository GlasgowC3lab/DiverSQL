WITH page_durations AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_number,
        sd.d_date AS start_date,
        ed.d_date AS end_date,
        date_diff('day', sd.d_date, ed.d_date) AS duration_days,
        sd.d_fy_year AS start_fy_year,
        ed.d_fy_year AS end_fy_year,
        sd.d_current_month AS start_month,
        ed.d_current_month AS end_month
    FROM catalog_page cp
    JOIN date_dim sd ON cp.cp_start_date_sk = sd.d_date_sk
    JOIN date_dim ed ON cp.cp_end_date_sk = ed.d_date_sk
    WHERE cp.cp_type IN ('quarterly', 'monthly')
),
aggregated AS (
    SELECT
        pd.cp_department AS department,
        pd.cp_type AS catalog_type,
        COUNT(*) AS page_cnt,
        AVG(pd.duration_days) AS avg_duration_days,
        MIN(pd.duration_days) AS min_duration_days,
        MAX(pd.duration_days) AS max_duration_days
    FROM page_durations pd
    WHERE pd.start_fy_year = 2023
    GROUP BY pd.cp_department, pd.cp_type
    HAVING COUNT(*) >= 5
)
SELECT
    a.department,
    a.catalog_type,
    a.page_cnt,
    a.avg_duration_days,
    a.min_duration_days,
    a.max_duration_days,
    RANK() OVER (PARTITION BY a.catalog_type ORDER BY a.avg_duration_days DESC) AS dept_rank_by_avg_duration
FROM aggregated a
ORDER BY a.catalog_type, dept_rank_by_avg_duration
