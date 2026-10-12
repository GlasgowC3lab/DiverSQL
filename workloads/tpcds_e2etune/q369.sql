SELECT
    w.w_state AS state,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouse_cnt,
    SUM(w.w_warehouse_sq_ft) AS total_sq_ft,
    COUNT(DISTINCT ws.web_site_id) AS website_cnt,
    AVG(ws.web_tax_percentage) AS avg_tax_pct,
    sm.sm_carrier,
    sm.sm_type,
    sm.mode_cnt
FROM warehouse w
JOIN web_site ws
    ON w.w_state = ws.web_state
CROSS JOIN (
    SELECT
        sm_carrier,
        sm_type,
        COUNT(*) AS mode_cnt
    FROM ship_mode
    WHERE sm_type IN ('EXPRESS', 'NEXT DAY', 'OVERNIGHT')
    GROUP BY sm_carrier, sm_type
) sm
WHERE ws.web_rec_end_date IS NULL
  AND w.w_gmt_offset BETWEEN -5.00 AND -3.00
GROUP BY
    w.w_state,
    sm.sm_carrier,
    sm.sm_type,
    sm.mode_cnt
HAVING COUNT(DISTINCT w.w_warehouse_id) > 2
ORDER BY total_sq_ft DESC
LIMIT 100
