WITH store_metrics AS (
    SELECT
        s_city,
        s_state,
        s_zip,
        AVG(CAST(s_floor_space AS double) / NULLIF(s_number_employees, 0)) AS avg_floor_space_per_emp,
        COUNT(*) AS store_cnt
    FROM store
    WHERE s_number_employees > 0
      AND s_floor_space IS NOT NULL
    GROUP BY s_city, s_state, s_zip
),
warehouse_metrics AS (
    SELECT
        w_city,
        w_state,
        w_zip,
        AVG(CAST(w_warehouse_sq_ft AS double)) AS avg_warehouse_sq_ft,
        COUNT(*) AS warehouse_cnt
    FROM warehouse
    GROUP BY w_city, w_state, w_zip
),
time_filter AS (
    SELECT t_shift
    FROM time_dim
    WHERE t_shift = 'Morning'
      AND t_hour BETWEEN 8 AND 12
    LIMIT 1
)
SELECT
    sm.s_city,
    sm.s_state,
    sm.s_zip,
    sm.store_cnt,
    wm.warehouse_cnt,
    sm.avg_floor_space_per_emp,
    wm.avg_warehouse_sq_ft,
    (sm.avg_floor_space_per_emp / NULLIF(wm.avg_warehouse_sq_ft, 0)) AS ratio_floor_to_warehouse
FROM store_metrics sm
JOIN warehouse_metrics wm
    ON sm.s_city = wm.w_city
   AND sm.s_state = wm.w_state
   AND sm.s_zip = wm.w_zip
JOIN time_filter tf
    ON tf.t_shift = 'Morning'
WHERE sm.avg_floor_space_per_emp > 0
ORDER BY ratio_floor_to_warehouse DESC
LIMIT 100
