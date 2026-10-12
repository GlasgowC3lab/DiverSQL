SELECT ca.ca_state,
       d.d_year,
       COUNT(*) AS address_cnt,
       AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
       SUM(CASE WHEN ca.ca_street_type = 'Parkway' THEN 1 ELSE 0 END) AS parkway_cnt,
       MIN(d.d_date) AS earliest_date,
       MAX(d.d_date) AS latest_date
FROM customer_address ca
JOIN date_dim d ON 1 = 1
WHERE ca.ca_country = 'United States'
  AND ca.ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
  AND d.d_year = 2022
  AND d.d_month_seq BETWEEN 1 AND 12
GROUP BY ca.ca_state, d.d_year
HAVING COUNT(*) > 10
ORDER BY address_cnt DESC
LIMIT 100
