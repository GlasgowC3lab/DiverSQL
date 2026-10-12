WITH item_str AS (
    SELECT
        i.i_item_sk AS i_item_sk,
        i.i_product_name,
        lower(i.i_product_name) AS product_name_lc,
        upper(i.i_product_name) AS product_name_uc,
        substr(i.i_product_name, 1, 5) AS product_prefix,
        replace(i.i_product_name, ' ', '_') AS product_underscored,
        regexp_replace(i.i_product_name, '[aeiouAEIOU]', '') AS product_no_vowels,
        reverse(i.i_product_name) AS product_rev,
        length(i.i_product_name) AS product_len,
        position('red' IN lower(i.i_product_name)) AS pos_red,
        regexp_like(i.i_product_name, '(?i)pro|ultra') AS is_pro_ultra,
        cardinality(split(i.i_product_name, '')) AS char_count
    FROM item i
),
customer_str AS (
    SELECT
        c.c_customer_sk AS c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        lower(c.c_email_address) AS email_lc,
        regexp_extract(c.c_email_address, '@([^.]*)', 1) AS email_domain,
        length(c.c_login) AS login_len,
        replace(c.c_login, '-', '') AS login_clean,
        substr(c.c_login, 1, 3) AS login_prefix,
        cardinality(split(c.c_first_name, '')) AS first_name_char_cnt,
        trim(both ' ' FROM c.c_first_name) AS first_name_trim,
        regexp_like(c.c_first_name, '^[A-Z]') AS first_name_starts_upper
    FROM customer c
),
sales_str AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        i.product_prefix,
        i.product_no_vowels,
        i.product_rev,
        i.product_len,
        i.pos_red,
        i.is_pro_ultra,
        c.full_name,
        c.email_domain,
        c.login_len,
        c.login_clean,
        c.first_name_trim
    FROM catalog_sales cs
    JOIN item_str i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_str c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_quantity > 0
)
SELECT
    d.d_year,
    substr(s.product_prefix, 1, 3) AS prod_code3,
    s.email_domain,
    CASE WHEN s.pos_red > 0 THEN 'contains_red' ELSE 'no_red' END AS red_flag,
    s.is_pro_ultra,
    SUM(s.cs_quantity) AS total_qty,
    AVG(s.cs_quantity) AS avg_qty,
    COUNT(*) AS sales_cnt,
    approx_distinct(s.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT s.cs_item_sk) AS distinct_items,
    MAX(s.product_len) AS max_product_len,
    MIN(s.product_len) AS min_product_len,
    AVG(length(s.full_name) - length(replace(s.full_name, ' ', '')) + 1) AS avg_name_word_cnt,
    AVG(s.login_len) AS avg_login_len,
    MAX(concat_ws('-', substr(s.product_rev, 1, 3), substr(s.product_rev, length(s.product_rev) - 2, 3))) AS rev_sig,
    MAX(replace(s.product_no_vowels, ' ', '-')) AS product_no_vowels_dash,
    MAX(concat(s.first_name_trim, '_', s.login_clean)) AS user_key
FROM sales_str s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    substr(s.product_prefix, 1, 3),
    s.email_domain,
    CASE WHEN s.pos_red > 0 THEN 'contains_red' ELSE 'no_red' END,
    s.is_pro_ultra
ORDER BY d.d_year DESC, total_qty DESC
LIMIT 100
