SELECT
    d.d_year,
    s.s_state,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(LENGTH(i.i_product_name)) AS avg_product_name_len,
    AVG(LENGTH(REGEXP_REPLACE(i.i_product_name, '[^A-Z]', ''))) AS avg_uppercase_letter_cnt,
    SUM(CASE WHEN REGEXP_LIKE(i.i_product_name, '[0-9]{3}') THEN 1 ELSE 0 END) AS prod_name_has_three_digits,
    SUM(LENGTH(REGEXP_REPLACE(i.i_product_name, '[A-Z]', ''))) AS total_non_uppercase_chars,
    SUM(CAST(REGEXP_EXTRACT(i.i_product_name, '([0-9]+)', 1) AS INTEGER)) AS sum_product_numbers,
    SUM(LENGTH(element_at(SPLIT(c.c_email_address, '@'), 2))) AS total_email_domain_len,
    COUNT(DISTINCT REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1)) AS distinct_email_domains,
    SUM(CASE WHEN STRPOS(LOWER(c.c_email_address), 'gmail.com') > 0 THEN 1 ELSE 0 END) AS gmail_count,
    SUM(LENGTH(CONCAT_WS(' ', i.i_product_name, i.i_brand, i.i_color, i.i_size, c.c_first_name, c.c_last_name))) AS total_concat_len,
    SUM(LENGTH(REPLACE(CONCAT_WS(',', s.s_store_name, s.s_manager, s.s_city), ' ', ''))) AS total_cleaned_store_info_len,
    AVG(LENGTH(REVERSE(ca.ca_city))) AS avg_rev_city_len,
    SUM(CAST(REGEXP_REPLACE(ca.ca_zip, '[^0-9]', '') AS INTEGER)) AS sum_zip_digits,
    COUNT(DISTINCT SUBSTR(c.c_login, 1, 3)) AS distinct_login_prefixes,
    AVG(LENGTH(TRIM(s.s_manager))) AS avg_trimmed_manager_len
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, s.s_state
ORDER BY d.d_year, s.s_state
