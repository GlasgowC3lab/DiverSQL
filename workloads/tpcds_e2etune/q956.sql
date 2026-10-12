WITH store_agg AS (
    SELECT
        s_city,
        s_state,
        COUNT(*) AS store_cnt,
        SUM(s_floor_space) AS total_floor_space,
        AVG(s_floor_space) AS avg_floor_space,
        SUM(s_number_employees) AS total_employees,
        MIN(s_rec_start_date) AS earliest_start_date,
        MAX(s_rec_start_date) AS latest_start_date
    FROM store
    WHERE s_rec_start_date >= DATE '2000-01-01'
      AND s_floor_space > 5000000
    GROUP BY s_city, s_state
    HAVING COUNT(*) >= 2
),
warehouse_agg AS (
    SELECT
        w_city,
        w_state,
        COUNT(*) AS warehouse_cnt,
        SUM(w_warehouse_sq_ft) AS total_warehouse_sq_ft,
        AVG(w_warehouse_sq_ft) AS avg_warehouse_sq_ft,
        MIN(w_warehouse_id) AS first_warehouse_id
    FROM warehouse
    WHERE w_warehouse_sq_ft >= 1000000
    GROUP BY w_city, w_state
)
SELECT
    s.s_city,
    s.s_state,
    s.store_cnt,
    s.total_floor_space,
    w.warehouse_cnt,
    w.total_warehouse_sq_ft,
    CAST(s.total_floor_space AS DOUBLE) / NULLIF(w.total_warehouse_sq_ft, 0) AS floor_to_warehouse_ratio,
    RANK() OVER (ORDER BY CAST(s.total_floor_space AS DOUBLE) / NULLIF(w.total_warehouse_sq_ft, 0) DESC) AS floor_ratio_rank
FROM store_agg s
JOIN warehouse_agg w
  ON s.s_city = w.w_city
 AND s.s_state = w.w_state
WHERE w.total_warehouse_sq_ft > 0
ORDER BY floor_to_warehouse_ratio DESC
LIMIT 50
