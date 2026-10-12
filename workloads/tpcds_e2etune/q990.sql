WITH base AS (
    SELECT
        cp.cp_department,
        ws.web_state,
        sm.sm_carrier,
        COUNT(*) AS total_rows,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS distinct_pages,
        AVG(ws.web_tax_percentage) AS avg_tax,
        SUM(CASE WHEN cp.cp_type = 'monthly' THEN 1 ELSE 0 END) AS monthly_page_count
    FROM catalog_page cp
    JOIN web_site ws
        ON cp.cp_start_date_sk = ws.web_open_date_sk
    JOIN ship_mode sm
        ON cp.cp_type = sm.sm_type
    WHERE cp.cp_type IN ('monthly', 'quarterly')
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND ws.web_country = 'United States'
      AND sm.sm_type IS NOT NULL
    GROUP BY cp.cp_department, ws.web_state, sm.sm_carrier
    HAVING COUNT(*) > 5
)
SELECT
    cp_department,
    web_state,
    sm_carrier,
    total_rows,
    distinct_pages,
    avg_tax,
    monthly_page_count,
    RANK() OVER (ORDER BY total_rows DESC) AS rank_by_rows
FROM base
ORDER BY total_rows DESC, rank_by_rows
