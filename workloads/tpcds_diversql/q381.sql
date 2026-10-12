SELECT
  ca.ca_city,
  ca.ca_state,
  COUNT(*) AS customer_cnt
FROM tpcds.customer AS c
JOIN tpcds.customer_address AS ca
  ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_county = 'Maricopa County'
  AND c.c_birth_year = 1980
GROUP BY ca.ca_city, ca.ca_state
ORDER BY customer_cnt DESC
