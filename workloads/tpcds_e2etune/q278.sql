SELECT
    r.r_reason_desc,
    w.w_state,
    COUNT(*) AS cnt,
    AVG(w.w_warehouse_sq_ft) AS avg_sqft,
    SUM(w.w_warehouse_sq_ft) AS total_sqft,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY SUM(w.w_warehouse_sq_ft) DESC) AS reason_rank_in_state
FROM reason r
JOIN warehouse w
    ON 1 = 1
WHERE r.r_reason_desc IN ('Package was damaged', 'Stopped working', 'Did not get it on time')
  AND w.w_state IN ('NM', 'SD', 'OH', 'SC')
  AND w.w_warehouse_sq_ft > 0
GROUP BY r.r_reason_desc, w.w_state
HAVING COUNT(*) > 5
ORDER BY total_sqft DESC
LIMIT 100
