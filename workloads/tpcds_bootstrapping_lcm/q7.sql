WITH agg AS (
    SELECT
        d.d_year,
        d.d_current_quarter,
        COUNT(DISTINCT s.s_store_id) AS store_count,
        SUM(s.s_floor_space) AS total_floor_space,
        AVG(s.s_number_employees) AS avg_employees,
        MAX(s.s_floor_space) AS max_floor_space,
        MIN(s.s_floor_space) AS min_floor_space,
        SUM(CASE WHEN s.s_tax_percentage > 5 THEN 1 ELSE 0 END) AS high_tax_store_count,
        AVG(s.s_floor_space) FILTER (WHERE d.d_holiday = 'Y') AS avg_floor_space_holiday,
        SUM(s.s_floor_space) * 0.01 AS estimated_tax_revenue,
        SUM(CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_closure_count
    FROM date_dim d
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2022
      AND s.s_state = 'CA'
    GROUP BY d.d_year, d.d_current_quarter
    HAVING COUNT(DISTINCT s.s_store_id) > 5
)
SELECT
    a.d_year,
    a.d_current_quarter,
    a.store_count,
    a.total_floor_space,
    a.avg_employees,
    a.max_floor_space,
    a.min_floor_space,
    a.high_tax_store_count,
    a.avg_floor_space_holiday,
    a.estimated_tax_revenue,
    a.holiday_closure_count,
    ROUND(100.0 * a.holiday_closure_count / a.store_count, 2) AS holiday_closure_pct,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_floor_space DESC) AS floor_space_rank_in_year
FROM agg a
ORDER BY a.d_year DESC, a.d_current_quarter
