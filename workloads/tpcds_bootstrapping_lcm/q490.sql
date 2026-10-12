SELECT
    d.d_year AS dim_year,
    catalog_page.cp_department,
    store.s_state,
    web_site.web_state,
    COUNT(DISTINCT customer.c_customer_id) AS distinct_customers,
    COUNT(*) AS total_rows,
    SUM(store.s_number_employees) AS total_store_employees,
    AVG(store.s_tax_percentage) AS avg_store_tax_pct
FROM catalog_page
JOIN date_dim AS d
    ON catalog_page.cp_end_date_sk = d.d_date_sk
JOIN store
    ON store.s_closed_date_sk = d.d_date_sk
JOIN web_site
    ON web_site.web_open_date_sk = d.d_date_sk
JOIN customer
    ON customer.c_first_shipto_date_sk = d.d_date_sk
GROUP BY CUBE (d.d_year, catalog_page.cp_department, store.s_state, web_site.web_state)
HAVING COUNT(*) > 0
ORDER BY dim_year, catalog_page.cp_department, store.s_state, web_site.web_state
LIMIT 100
