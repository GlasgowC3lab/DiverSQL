WITH cc_stats AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_division,
        cc.cc_tax_percentage,
        cc.cc_employees,
        cc.cc_sq_ft,
        cc.cc_closed_date_sk,
        date_diff('day', d_open.d_date, d_closed.d_date) AS days_open_to_close
    FROM call_center cc
    JOIN date_dim d_closed
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
),
store_stats AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_tax_percentage,
        s.s_number_employees,
        s.s_floor_space,
        s.s_closed_date_sk,
        d_closed.d_weekend,
        d_closed.d_year
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
)
SELECT
    cc.cc_division,
    st.s_state,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
    COUNT(DISTINCT st.s_store_sk) AS num_stores,
    AVG(cc.days_open_to_close) AS avg_days_open_to_close,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(st.s_number_employees) AS total_store_employees,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(st.s_tax_percentage) AS avg_store_tax_pct,
    SUM(CASE WHEN st.d_weekend = 'Y' THEN 1 ELSE 0 END) AS stores_closed_on_weekend
FROM cc_stats cc
JOIN store_stats st
    ON cc.cc_closed_date_sk = st.s_closed_date_sk
WHERE st.d_year = 2022
GROUP BY cc.cc_division, st.s_state
ORDER BY cc.cc_division, st.s_state
LIMIT 50
