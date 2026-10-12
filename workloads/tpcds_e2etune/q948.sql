SELECT
    cc.cc_state AS state,
    cc.cc_city AS city,
    t.t_shift AS shift,
    COUNT(DISTINCT cc.cc_call_center_id) AS call_center_count,
    AVG(cc.cc_employees) AS avg_employees,
    SUM(cc.cc_sq_ft) AS total_sq_ft,
    COUNT(DISTINCT ca.ca_address_id) AS address_count,
    AVG(cc.cc_gmt_offset) AS avg_gmt_offset
FROM
    call_center cc
LEFT JOIN
    customer_address ca
    ON cc.cc_state = ca.ca_state
    AND cc.cc_city = ca.ca_city
    AND cc.cc_zip = ca.ca_zip
JOIN
    time_dim t
    ON t.t_hour = (cc.cc_open_date_sk % 24)
WHERE
    cc.cc_country = 'United States'
    AND cc.cc_state IN ('TN', 'LA', 'GA', 'MN', 'MI')
    AND cc.cc_closed_date_sk IS NULL
    AND ca.ca_location_type = 'Residential'
GROUP BY
    cc.cc_state,
    cc.cc_city,
    t.t_shift
HAVING
    COUNT(DISTINCT cc.cc_call_center_id) > 0
ORDER BY
    avg_employees DESC,
    call_center_count DESC
LIMIT 50
