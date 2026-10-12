WITH filtered_sales AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cp.cp_department,
        d.d_year,
        ca.ca_city,
        cp.cp_description,
        regexp_extract(cp.cp_description, '(\\d{3})', 1) AS desc_code
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cp.cp_description, '(?i)sale')
      AND ca.ca_city LIKE 'San%'
)
SELECT
    cp_department,
    d_year,
    desc_code,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_quantity) AS total_quantity,
    CONCAT(SUBSTR(ca_city, 1, 3), '-', cp_department) AS city_dept_key
FROM filtered_sales
GROUP BY cp_department, d_year, desc_code, ca_city
ORDER BY total_sales DESC
LIMIT 100
