SELECT
    c.c_preferred_cust_flag,
    d.d_year,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count
FROM
    customer c
JOIN
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN
    date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
WHERE
    c.c_birth_year = 1925
    AND hd.hd_buy_potential = '1001-5000      '
GROUP BY
    c.c_preferred_cust_flag,
    d.d_year
ORDER BY
    customer_count DESC
