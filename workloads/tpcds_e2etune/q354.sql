WITH cp_bucket AS (
  SELECT cp.*, (cp.cp_catalog_number % 3) AS bucket_r, (cp.cp_catalog_page_sk % 5) AS bucket_ca
  FROM catalog_page cp
  WHERE cp.cp_type = 'quarterly' AND cp.cp_department = 'DEPARTMENT'
),
 r_bucket AS (
  SELECT r.*, (r.r_reason_sk % 3) AS bucket_r
  FROM reason r
),
 ca_bucket AS (
  SELECT ca.*, (ca.ca_address_sk % 5) AS bucket_ca
  FROM customer_address ca
  WHERE ca.ca_country = 'United States'
)
SELECT cp.cp_department,
       r.r_reason_desc,
       ca.ca_state,
       COUNT(DISTINCT cp.cp_catalog_page_id) AS total_pages,
       AVG(cp.cp_catalog_number) AS avg_catalog_number,
       SUM(ca.ca_gmt_offset) AS sum_gmt_offset,
       MAX(cp.cp_end_date_sk) AS max_end_date_sk,
       MIN(cp.cp_start_date_sk) AS min_start_date_sk
FROM cp_bucket cp
JOIN r_bucket r ON cp.bucket_r = r.bucket_r
JOIN ca_bucket ca ON cp.bucket_ca = ca.bucket_ca
GROUP BY cp.cp_department, r.r_reason_desc, ca.ca_state
HAVING COUNT(DISTINCT cp.cp_catalog_page_id) > 5
ORDER BY total_pages DESC, avg_catalog_number ASC
LIMIT 100
