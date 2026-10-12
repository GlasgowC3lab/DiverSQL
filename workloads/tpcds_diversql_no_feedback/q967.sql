WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_page_number,
        cp.cp_description,
        regexp_extract(cp.cp_description, '(\\d{2})') AS two_digit_code,
        concat(cp.cp_department, ':', CAST(cp.cp_catalog_page_number AS varchar)) AS page_label
    FROM catalog_page cp
    WHERE cp.cp_description LIKE '%store%'
      AND regexp_like(cp.cp_description, '[0-9]{2}')
)
SELECT
    fp.cp_catalog_page_id,
    fp.cp_department,
    fp.two_digit_code,
    fp.page_label,
    SUM(cs.cs_ext_sales_price) AS total_sales
FROM filtered_pages fp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY fp.cp_catalog_page_id, fp.cp_department, fp.two_digit_code, fp.page_label
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
