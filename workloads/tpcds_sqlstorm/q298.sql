SELECT
    d.d_year,
    d.d_moy AS month,
    COUNT(*) AS sales_transactions,
    SUM(cs.cs_net_paid) AS total_net_paid,
    ROUND(AVG(length(i.i_item_desc)), 2) AS avg_item_desc_len,
    AVG(cardinality(regexp_split(i.i_item_desc, '\\s+'))) AS avg_item_desc_word_cnt,
    SUM(CASE WHEN lower(i.i_item_desc) LIKE '%steel%' THEN 1 ELSE 0 END) AS steel_item_cnt,
    COUNT(DISTINCT CONCAT_WS('_', c.c_first_name, c.c_last_name)) AS distinct_customers,
    COUNT(DISTINCT lower(regexp_extract(c.c_email_address, '@(.+)$', 1))) AS distinct_email_domains,
    SUM(CASE WHEN regexp_like(c.c_email_address, '^.+@example\\.com$') THEN cs.cs_net_paid ELSE 0 END) AS example_com_sales,
    SUM(CASE WHEN length(c.c_login) > 10 THEN cs.cs_net_paid ELSE 0 END) AS long_login_sales,
    ROUND(AVG(length(regexp_replace(i.i_product_name, '\\s+', ''))), 2) AS avg_product_name_nospace_len,
    SUM(CAST(regexp_extract(i.i_product_name, '(\\d+)', 1) AS integer)) AS sum_first_number_in_product_name,
    COUNT(*) FILTER (WHERE upper(i.i_color) = 'RED') AS red_color_sales_cnt,
    AVG(cardinality(regexp_split(p.cp_description, '\\s+'))) AS avg_page_desc_word_cnt,
    SUM(CASE WHEN lower(p.cp_type) = 'promotion' THEN cs.cs_net_paid ELSE 0 END) AS promotion_type_sales,
    MAX(length(regexp_replace(p.cp_department, '[^A-Za-z]', ''))) AS max_clean_department_len,
    COUNT(DISTINCT substr(i.i_product_name, 1, 5)) AS distinct_product_prefix_5_cnt,
    SUM(CASE WHEN substr(lower(i.i_product_name), 1, 3) = 'the' THEN cs.cs_net_paid ELSE 0 END) AS sales_product_name_starts_the,
    AVG(length(reverse(i.i_product_name))) AS avg_reversed_name_len
FROM
    catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page p ON cs.cs_catalog_page_sk = p.cp_catalog_page_sk
WHERE
    d.d_year BETWEEN 2000 AND 2002
GROUP BY
    d.d_year,
    d.d_moy
ORDER BY
    d.d_year,
    d.d_moy
