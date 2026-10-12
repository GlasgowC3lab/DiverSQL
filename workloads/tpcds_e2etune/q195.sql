SELECT cp.cp_department,
       ws.web_country,
       COUNT(DISTINCT c.c_customer_sk) AS num_customers,
       SUM(cp.cp_catalog_page_number) AS total_page_numbers,
       AVG(ws.web_gmt_offset) AS avg_gmt_offset
FROM catalog_page cp
JOIN web_site ws
  ON cp.cp_start_date_sk = ws.web_open_date_sk
JOIN customer c
  ON c.c_first_shipto_date_sk = cp.cp_end_date_sk
WHERE cp.cp_catalog_page_number IN (1, 2, 5)
  AND ws.web_state = 'CA'
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY cp.cp_department, ws.web_country
HAVING COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY total_page_numbers DESC
LIMIT 50
