SELECT cp.cp_catalog_page_id,
       cp.cp_description,
       d.d_date
FROM   catalog_page cp
JOIN   date_dim d
     ON cp.cp_end_date_sk = d.d_date_sk
WHERE  cp.cp_type = 'monthly'
  AND  d.d_following_holiday = 'Y'
ORDER BY d.d_date
LIMIT 100
