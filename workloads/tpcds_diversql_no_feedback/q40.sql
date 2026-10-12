WITH date_agg AS (
    SELECT
        d_date_sk,
        d_year,
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_cnt
    FROM date_dim
    WHERE d_year >= 2000
      AND d_year <= 2005
      AND d_month_seq BETWEEN 4 AND 19
      AND d_current_week = 'N'
    GROUP BY d_date_sk, d_year
)
SELECT
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    st.s_number_employees,
    da.d_year,
    da.holiday_cnt,
    RANK() OVER (PARTITION BY st.s_state ORDER BY st.s_number_employees DESC) AS employee_rank,
    CASE
        WHEN st.s_number_employees >= 250 THEN 'Large'
        WHEN st.s_number_employees >= 230 THEN 'Medium'
        ELSE 'Small'
    END AS size_category,
    (
        SELECT MAX(hc)
        FROM (
            SELECT d_year, SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS hc
            FROM date_dim
            GROUP BY d_year
        ) yr
        WHERE yr.d_year = da.d_year
    ) AS max_holiday_in_year
FROM store st
JOIN date_agg da
  ON st.s_closed_date_sk = da.d_date_sk
WHERE st.s_state = 'CA'
  AND st.s_number_employees > 220
  AND st.s_city IN ('Buena Vista', 'Riverside', 'Pleasant Valley')
  AND EXISTS (
        SELECT 1
        FROM store s2
        WHERE s2.s_city = st.s_city
          AND s2.s_number_employees > st.s_number_employees
    )
ORDER BY da.d_year DESC, employee_rank ASC
LIMIT 100
