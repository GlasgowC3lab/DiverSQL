SELECT
    s.s_store_name AS store_name,
    d.d_year,
    i.i_category AS category,
    i.i_brand AS brand,
    COUNT(*) AS total_sales_transactions,
    SUM(ss.ss_net_paid) AS total_revenue,
    AVG(ss.ss_quantity) AS avg_quantity,
    SUM(CASE WHEN lower(i.i_color) = 'red' THEN ss.ss_quantity ELSE 0 END) AS red_items_quantity,
    MIN(d.d_date) AS first_sale_date,
    MAX(d.d_date) AS last_sale_date,
    AVG(LENGTH(i.i_product_name)) AS avg_product_name_len,
    MAX(LENGTH(REGEXP_REPLACE(i.i_product_name, '[^A-Za-z0-9]', ''))) AS max_alnum_product_name_len,
    COUNT(DISTINCT CONCAT(LOWER(i.i_brand), '-', LOWER(i.i_color), '-', LOWER(i.i_size))) AS distinct_signatures,
    COUNT(DISTINCT REGEXP_REPLACE(LOWER(c.c_email_address), '.*@', '')) AS distinct_email_domains,
    AVG(cardinality(split(i.i_product_name, ' '))) AS avg_product_name_word_count,
    array_join(array_agg(DISTINCT i.i_product_name), ' | ') AS distinct_product_names_concat,
    MIN(LENGTH(REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1))) AS min_email_domain_len,
    MAX(LENGTH(REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1))) AS max_email_domain_len,
    approx_percentile(CAST(LENGTH(i.i_product_name) AS DOUBLE), 0.5) AS median_product_name_len,
    COUNT(DISTINCT lower(ca.ca_city)) AS distinct_cities_served,
    AVG(LENGTH(ca.ca_city)) AS avg_city_name_len,
    array_join(array_agg(DISTINCT ca.ca_city), ', ') AS city_list
FROM
    store_sales ss
JOIN
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN
    customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    d.d_year BETWEEN 1999 AND 2002
    AND ss.ss_quantity > 0
    AND s.s_state = 'CA'
    AND i.i_product_name IS NOT NULL
GROUP BY
    s.s_store_name,
    d.d_year,
    i.i_category,
    i.i_brand
HAVING
    COUNT(*) > 500
ORDER BY
    total_revenue DESC
LIMIT 100
