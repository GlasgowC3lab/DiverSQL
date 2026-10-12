WITH filtered_cc AS (
    SELECT
        cc_call_center_sk,
        cc_call_center_id,
        cc_name,
        cc_mkt_class,
        cc_city,
        cc_state,
        cc_employees,
        cc_open_date_sk,
        cc_closed_date_sk,
        regexp_extract(cc_hours, '(\\d{2}:\\d{2})-(\\d{2}:\\d{2})', 1) AS open_time,
        concat(cc_city, ', ', cc_state) AS location
    FROM tpcds.call_center
    WHERE regexp_like(cc_mkt_class, '^Associated')
      AND cc_city LIKE '%C%'
)
SELECT
    COALESCE(date_dim.d_year, -1) AS year,
    COALESCE(date_dim.d_month_seq, -1) AS month_seq,
    COUNT(DISTINCT filtered_cc.cc_call_center_id) AS num_call_centers,
    SUM(filtered_cc.cc_employees) AS total_employees,
    COUNT(*) AS total_rows,
    MAX(filtered_cc.open_time) AS sample_open_time,
    MAX(filtered_cc.location) AS sample_location
FROM filtered_cc
FULL OUTER JOIN tpcds.date_dim AS date_dim
    ON (filtered_cc.cc_open_date_sk = date_dim.d_date_sk
        OR filtered_cc.cc_closed_date_sk = date_dim.d_date_sk)
WHERE (date_dim.d_year IS NULL OR date_dim.d_year BETWEEN 2000 AND 2005)
GROUP BY
    COALESCE(date_dim.d_year, -1),
    COALESCE(date_dim.d_month_seq, -1)
ORDER BY year DESC, month_seq
LIMIT 100
