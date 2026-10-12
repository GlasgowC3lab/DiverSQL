WITH page_stats AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        COUNT(*) AS catalog_page_cnt,
        AVG(DATE_DIFF('day', start_d.d_date, end_d.d_date)) AS avg_page_days,
        MIN(DATE_DIFF('day', start_d.d_date, end_d.d_date)) AS min_page_days,
        MAX(DATE_DIFF('day', start_d.d_date, end_d.d_date)) AS max_page_days,
        SUM(CASE WHEN EXISTS (
                SELECT 1 FROM income_band ib
                WHERE cp.cp_catalog_page_number BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
            ) THEN 1 ELSE 0 END) AS pages_in_income_band
    FROM catalog_page cp
    JOIN date_dim start_d ON cp.cp_start_date_sk = start_d.d_date_sk
    JOIN date_dim end_d ON cp.cp_end_date_sk = end_d.d_date_sk
    WHERE cp.cp_type IN ('bi-annual', 'quarterly')
      AND start_d.d_year = 2022
    GROUP BY cp.cp_department, cp.cp_type
)
SELECT
    cp_department,
    cp_type,
    catalog_page_cnt,
    avg_page_days,
    min_page_days,
    max_page_days,
    pages_in_income_band,
    RANK() OVER (ORDER BY avg_page_days DESC) AS duration_rank
FROM page_stats
ORDER BY avg_page_days DESC
LIMIT 50
