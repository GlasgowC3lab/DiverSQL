SELECT cr.cr_return_amount,
       cr.cr_store_credit,
       cp.cp_department,
       cp.cp_catalog_page_id
FROM tpcds.catalog_returns AS cr
JOIN tpcds.catalog_page AS cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cr.cr_store_credit > 500
  AND cp.cp_catalog_number = 14
LIMIT 100
