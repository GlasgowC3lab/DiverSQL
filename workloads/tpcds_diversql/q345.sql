SELECT
    d.d_year,
    COUNT(DISTINCT c.c_customer_id) AS preferred_customers_cnt
FROM tpcds.customer c
JOIN tpcds.date_dim d
  ON c.c_first_shipto_date_sk = d.d_date_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND d.d_moy = 7
GROUP BY d.d_year
ORDER BY d.d_year
