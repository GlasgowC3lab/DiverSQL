WITH agg AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS band_count,
        SUM(ib.ib_upper_bound) AS total_upper_bound,
        AVG(ib.ib_lower_bound) AS avg_lower_bound
    FROM income_band ib
    JOIN reason r
        ON ib.ib_income_band_sk = r.r_reason_sk
    WHERE ib.ib_upper_bound >= 20000
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_desc
    HAVING COUNT(*) > 0
)
SELECT
    r_reason_desc,
    band_count,
    total_upper_bound,
    avg_lower_bound,
    RANK() OVER (ORDER BY total_upper_bound DESC) AS reason_rank
FROM agg
ORDER BY total_upper_bound DESC
LIMIT 5
