SELECT
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    MIN(d.d_date) AS earliest_ship_date,
    MAX(d.d_date) AS latest_ship_date
FROM customer c
JOIN date_dim d
  ON c.c_first_shipto_date_sk = d.d_date_sk
WHERE d.d_fy_week_seq = 14
  AND d.d_dow = 3
  AND c.c_preferred_cust_flag = 'Y'
