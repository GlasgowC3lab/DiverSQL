SELECT cp_catalog_page_id,
       cp_department,
       cp_catalog_page_number,
       cp_description
FROM tpcds.catalog_page
WHERE cp_catalog_page_number IN (10, 13, 17)
  AND cp_start_date_sk BETWEEN 2450900 AND 2451000
ORDER BY cp_catalog_page_number ASC
LIMIT 10
