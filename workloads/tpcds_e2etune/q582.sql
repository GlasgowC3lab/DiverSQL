WITH store_filtered AS (
    SELECT
        s_store_sk,
        s_state,
        s_city,
        s_county,
        s_manager,
        s_floor_space,
        s_tax_percentage,
        s_number_employees,
        s_closed_date_sk
    FROM store
    WHERE s_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
      AND s_tax_percentage >= 5.00
      AND s_number_employees > 30
      AND s_state IN ('CA', 'TX', 'NY', 'FL')
),
time_filtered AS (
    SELECT
        t_time_sk,
        t_shift,
        t_meal_time,
        t_hour
    FROM time_dim
    WHERE t_meal_time = 'Lunch'
      AND t_shift IN ('Morning', 'Afternoon')
),
agg AS (
    SELECT
        sf.s_state,
        tf.t_shift,
        COUNT(DISTINCT sf.s_city) AS city_cnt,
        COUNT(*) AS store_cnt,
        AVG(sf.s_tax_percentage) AS avg_tax_pct,
        SUM(sf.s_floor_space) AS total_floor_space,
        MAX(sf.s_number_employees) AS max_employees
    FROM store_filtered sf
    JOIN time_filtered tf
        ON sf.s_closed_date_sk = tf.t_time_sk
    GROUP BY sf.s_state, tf.t_shift
    HAVING COUNT(*) >= 5
)
SELECT
    s_state,
    t_shift,
    city_cnt,
    store_cnt,
    avg_tax_pct,
    total_floor_space,
    max_employees,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY avg_tax_pct DESC) AS tax_rank_state
FROM agg
ORDER BY avg_tax_pct DESC, total_floor_space DESC
LIMIT 25
