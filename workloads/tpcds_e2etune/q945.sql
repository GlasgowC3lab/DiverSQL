WITH cp_agg AS (
  SELECT
    cp.cp_department,
    d_start.d_year,
    d_start.d_month_seq,
    ca.ca_country,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(CASE WHEN cd.cd_education_status = 'College' THEN 1 ELSE 0 END) AS college_educated_rate,
    AVG(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_rate
  FROM catalog_page cp
  JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
  LEFT JOIN customer c ON c.c_first_shipto_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE cp.cp_type = 'monthly'
    AND cp.cp_department = 'DEPARTMENT'
    AND d_start.d_year = 2021
  GROUP BY cp.cp_department, d_start.d_year, d_start.d_month_seq, ca.ca_country
  HAVING COUNT(DISTINCT cp.cp_catalog_page_sk) > 0
)
SELECT
  cp_department,
  d_year,
  d_month_seq,
  ca_country,
  num_pages,
  distinct_customers,
  college_educated_rate,
  male_rate,
  RANK() OVER (PARTITION BY d_year ORDER BY num_pages DESC) AS dept_page_rank
FROM cp_agg
ORDER BY d_year, d_month_seq, num_pages DESC
LIMIT 100
