SELECT
    s.s_store_name,
    s.s_state,
    d_closure.d_year AS closure_year,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_cnt,
    (
        SELECT COUNT(DISTINCT ws2.web_site_id)
        FROM web_site ws2
        JOIN date_dim d_ws2
          ON ws2.web_open_date_sk = d_ws2.d_date_sk
        WHERE d_ws2.d_year = d_closure.d_year
    ) AS num_web_sites_opened
FROM store s
JOIN date_dim d_closure
  ON s.s_closed_date_sk = d_closure.d_date_sk
LEFT JOIN customer c
  ON c.c_first_sales_date_sk = d_closure.d_date_sk
LEFT JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE d_closure.d_year BETWEEN 2000 AND 2020
  AND (c.c_birth_month IN (4, 7, 9) OR c.c_birth_month IS NULL)
GROUP BY s.s_store_name, s.s_state, d_closure.d_year
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY num_customers DESC
LIMIT 100
