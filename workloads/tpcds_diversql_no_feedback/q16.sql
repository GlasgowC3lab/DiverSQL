SELECT
  ca.ca_city,
  ca.ca_state,
  count(*) AS customer_count
FROM tpcds.customer c
JOIN tpcds.customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_location_type = 'condo'
  AND c.c_birth_day = 14
GROUP BY ca.ca_city, ca.ca_state
ORDER BY customer_count DESC
LIMIT 10
