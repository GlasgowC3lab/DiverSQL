SELECT
    c.c_customer_id,
    d.d_year,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    CASE WHEN c.c_preferred_cust_flag = 'N' THEN c.c_email_address END AS preferred_email,
    (SELECT d2.d_year FROM date_dim d2 WHERE d2.d_year < 1925 ORDER BY d2.d_year DESC LIMIT 1) AS max_year_before_param
FROM store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE d.d_year = 1925
  AND t.t_hour >= 3
GROUP BY c.c_customer_id, d.d_year, c.c_customer_sk, c.c_preferred_cust_flag, c.c_email_address
HAVING SUM(sr.sr_return_amt) > 48.04 AND COUNT(*) >= 500
