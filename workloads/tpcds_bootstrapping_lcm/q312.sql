WITH aggregated AS (
    SELECT
        d.d_current_year,
        d.d_quarter_name,
        s.s_state,
        COUNT(*) AS closures,
        SUM(CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_closures,
        AVG(s.s_floor_space) AS avg_floor_space,
        MAX(s.s_number_employees) AS max_employees,
        MIN(s.s_number_employees) AS min_employees,
        COUNT(DISTINCT s.s_store_id) AS distinct_stores
    FROM date_dim d
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2019-01-01' 
      AND d.d_date < DATE '2023-01-01'
    GROUP BY GROUPING SETS (
        (d.d_current_year, d.d_quarter_name, s.s_state),
        (d.d_current_year, d.d_quarter_name),
        (d.d_current_year),
        ()
    )
)
SELECT
    COALESCE(aggregated.d_current_year, 'ALL')   AS year,
    COALESCE(aggregated.d_quarter_name, 'ALL') AS quarter,
    COALESCE(aggregated.s_state, 'ALL')        AS state,
    aggregated.closures,
    aggregated.holiday_closures,
    aggregated.avg_floor_space,
    aggregated.max_employees,
    aggregated.min_employees,
    aggregated.distinct_stores,
    ROW_NUMBER() OVER (ORDER BY aggregated.closures DESC) AS rank_by_closures
FROM aggregated
WHERE aggregated.closures > 0
ORDER BY rank_by_closures
LIMIT 100
