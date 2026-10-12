SELECT
  ca_city,
  ca_state,
  COUNT(*) AS address_count
FROM tpcds.customer_address
WHERE ca_zip LIKE '3%'
  AND ca_gmt_offset > -5.00
GROUP BY ca_city, ca_state
ORDER BY address_count DESC
LIMIT 10
