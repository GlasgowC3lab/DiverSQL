SELECT cp_department,
       COUNT(DISTINCT cp_catalog_page_id) AS page_count,
       MIN(cp_start_date_sk) AS min_start_sk,
       MAX(cp_end_date_sk) AS max_end_sk
FROM catalog_page
WHERE cp_end_date_sk = 2451361
  AND cp_catalog_page_id LIKE 'AAAAAAA%'
GROUP BY cp_department
ORDER BY page_count DESC
LIMIT 10
