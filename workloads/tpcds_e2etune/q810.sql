WITH total_weekend_days AS (
    SELECT d_year,
           d_qoy,
           COUNT(*) AS total_weekend_days
    FROM date_dim
    WHERE d_weekend = 'Y'
      AND d_year BETWEEN 1900 AND 1904
    GROUP BY d_year, d_qoy
),
store_closure AS (
    SELECT s.s_store_id,
           d.d_year,
           d.d_qoy,
           COUNT(*) AS closed_days,
           AVG(s.s_floor_space) AS avg_floor_space
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'Y'
      AND d.d_year BETWEEN 1900 AND 1904
    GROUP BY s.s_store_id, d.d_year, d.d_qoy
)
SELECT sc.s_store_id,
       sc.d_year,
       sc.d_qoy AS quarter_of_year,
       sc.closed_days,
       sc.avg_floor_space,
       td.total_weekend_days,
       CAST(sc.closed_days AS double) / td.total_weekend_days AS closure_ratio,
       RANK() OVER (PARTITION BY sc.d_year ORDER BY sc.closed_days DESC) AS store_rank
FROM store_closure sc
JOIN total_weekend_days td
  ON sc.d_year = td.d_year AND sc.d_qoy = td.d_qoy
ORDER BY sc.d_year, store_rank
