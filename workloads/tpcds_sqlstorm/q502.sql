WITH item_strings AS (
    SELECT
        i_item_sk,
        i_category,
        i_brand,
        i_color,
        i_product_name,
        lower(i_product_name) AS product_name_lc,
        replace(i_product_name, '-', ' ') AS product_name_spaces,
        regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', '') AS item_desc_clean,
        length(i_item_desc) AS item_desc_len,
        cardinality(split(i_item_desc, ' ')) AS item_desc_word_cnt,
        CASE
            WHEN regexp_like(i_item_desc, '\\d+') THEN regexp_extract(i_item_desc, '(\\d+)', 1)
            ELSE NULL
        END AS first_number_in_desc,
        regexp_extract(i_product_name, '\\(([^)]+)\\)', 1) AS parenthetical_content
    FROM item
),
customer_strings AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        lower(c_email_address) AS email_lc,
        trim(both ' ' FROM concat_ws(' ', c.c_first_name, c.c_last_name)) AS full_name_trim,
        CASE
            WHEN regexp_like(c_email_address, '@([A-Za-z0-9.-]+)\\.(com|org|net|edu)$')
            THEN regexp_extract(c_email_address, '@([A-Za-z0-9.-]+)\\.', 1)
            ELSE NULL
        END AS email_domain,
        length(c.c_email_address) AS email_len
    FROM customer c
),
sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_paid,
        d.d_year,
        ca.ca_state,
        ca.ca_city
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    s.d_year,
    s.ca_state,
    i.i_category,
    COUNT(*) AS sales_cnt,
    SUM(s.cs_net_paid) AS total_net_paid,
    AVG(i.item_desc_len) AS avg_desc_len,
    AVG(i.item_desc_word_cnt) AS avg_desc_word_cnt,
    COUNT(DISTINCT c.email_domain) AS unique_email_domains,
    MAX(i.parenthetical_content) FILTER (WHERE i.parenthetical_content IS NOT NULL) AS max_paren_content,
    concat_ws(' | ', CAST(s.d_year AS VARCHAR), s.ca_state, i.i_category, CAST(COUNT(*) AS VARCHAR)) AS benchmark_key,
    any_value(lower(concat(i.i_brand, '-', i.i_color, '-', i.i_product_name))) AS normalized_product_name,
    any_value(regexp_replace(i.item_desc_clean, '\\s+', ' ')) AS normalized_desc
FROM sales_data s
JOIN item_strings i ON s.cs_item_sk = i.i_item_sk
JOIN customer_strings c ON s.cs_bill_customer_sk = c.c_customer_sk
WHERE s.d_year BETWEEN 1999 AND 2002
GROUP BY
    s.d_year,
    s.ca_state,
    i.i_category
ORDER BY total_net_paid DESC
LIMIT 100
