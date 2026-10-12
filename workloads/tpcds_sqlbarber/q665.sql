SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d.d_date,
    d.d_year,
    cp.cp_catalog_number * cp.cp_catalog_page_number AS catalog_product,
    cp.cp_catalog_number + cp.cp_catalog_page_number AS catalog_sum,
    CASE WHEN cp.cp_type = 'monthly' THEN 'Special' ELSE 'Regular' END AS type_category,
    CONCAT(cp.cp_description, ' - ', d.d_day_name) AS full_description,
    d.d_year - cp.cp_start_date_sk AS year_minus_start_sk
FROM catalog_page cp
JOIN date_dim d
  ON cp.cp_end_date_sk = d.d_date_sk
WHERE cp.cp_department = 'DEPARTMENT'
  AND d.d_year = 1914
