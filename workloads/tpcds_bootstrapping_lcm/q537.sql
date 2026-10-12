SELECT
    d_closed.d_year AS closure_year,
    d_closed.d_quarter_seq AS closure_quarter,
    CASE
        WHEN d_closed.d_quarter_seq IN (1, 2) THEN 'FirstHalf'
        ELSE 'SecondHalf'
    END AS half_year,
    s.s_state AS store_state,
    cc.cc_state AS call_center_state,
    COUNT(DISTINCT s.s_store_sk) AS num_stores_closed,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers_closed,
    SUM(s.s_floor_space) AS total_store_floor_space,
    SUM(cc.cc_sq_ft) AS total_call_center_sq_ft,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax_pct,
    AVG(date_diff('day', d_open.d_date, d_closed.d_date)) AS avg_days_open_to_close
FROM store s
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
WHERE s.s_state IS NOT NULL
  AND cc.cc_state IS NOT NULL
GROUP BY
    d_closed.d_year,
    d_closed.d_quarter_seq,
    CASE
        WHEN d_closed.d_quarter_seq IN (1, 2) THEN 'FirstHalf'
        ELSE 'SecondHalf'
    END,
    s.s_state,
    cc.cc_state
HAVING COUNT(DISTINCT s.s_store_sk) > 0
ORDER BY closure_year DESC, closure_quarter, store_state
