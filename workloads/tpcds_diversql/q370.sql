SELECT ca.ca_county,
       COUNT(DISTINCT c.c_customer_id) AS customer_cnt
FROM tpcds.customer AS c
JOIN tpcds.customer_address AS ca
  ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -5.00
  AND ca.ca_county = 'Kit Carson County'
GROUP BY ca.ca_county
ORDER BY customer_cnt DESC
