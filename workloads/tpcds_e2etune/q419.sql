WITH cust_state_agg AS (
  SELECT
    ca.ca_country,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(CASE WHEN c.c_birth_month = 12 THEN 1 ELSE 0 END) AS dec_births,
    AVG(c.c_birth_year) AS avg_birth_year
  FROM customer c
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE c.c_birth_day IN (8, 15, 19)
    AND c.c_birth_year BETWEEN 1960 AND 1990
    AND ca.ca_country = 'United States'
  GROUP BY ca.ca_country, ca.ca_state
  HAVING COUNT(DISTINCT c.c_customer_sk) >= 5
)
SELECT
  ca_country,
  ca_state,
  distinct_customers,
  dec_births,
  avg_birth_year,
  RANK() OVER (PARTITION BY ca_country ORDER BY dec_births DESC) AS birth_month12_state_rank,
  (SELECT avg(i_current_price) FROM item WHERE i_category = 'Electronics') AS avg_electronics_price,
  (SELECT count(DISTINCT sm_type) FROM ship_mode WHERE sm_carrier = 'UPS') AS ups_ship_mode_cnt,
  (SELECT avg(web_tax_percentage) FROM web_site WHERE web_state = ca_state) AS avg_state_web_tax
FROM cust_state_agg
ORDER BY dec_births DESC, avg_birth_year ASC
LIMIT 10
