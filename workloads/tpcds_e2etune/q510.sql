WITH agg AS (
    SELECT
        cc.cc_state,
        td_open.t_shift AS open_shift,
        td_close.t_shift AS close_shift,
        COUNT(*) AS center_cnt,
        AVG(cc.cc_tax_percentage) AS avg_tax,
        SUM(cc.cc_employees) AS total_emp,
        CASE WHEN AVG(cc.cc_tax_percentage) > 0.1 THEN 'HighTax' ELSE 'LowTax' END AS tax_category
    FROM call_center cc
    JOIN time_dim td_open ON cc.cc_open_date_sk = td_open.t_time_sk
    JOIN time_dim td_close ON cc.cc_closed_date_sk = td_close.t_time_sk
    WHERE cc.cc_state IN ('TN', 'LA', 'GA', 'MN', 'MI')
      AND cc.cc_tax_percentage IS NOT NULL
    GROUP BY cc.cc_state, td_open.t_shift, td_close.t_shift
    HAVING COUNT(*) > 2
)
SELECT
    cc_state,
    open_shift,
    close_shift,
    center_cnt,
    avg_tax,
    total_emp,
    tax_category,
    RANK() OVER (PARTITION BY cc_state ORDER BY avg_tax DESC) AS tax_rank
FROM agg
ORDER BY tax_rank, avg_tax DESC
LIMIT 100
