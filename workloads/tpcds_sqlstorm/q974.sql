WITH sales_join AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_login,
        s.s_store_name,
        s.s_city,
        i.i_product_name,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        d.d_year
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
metrics AS (
    SELECT
        s_store_name,
        s_city,
        c_first_name,
        c_last_name,
        c_email_address,
        c_login,
        i_product_name,
        i_item_desc,
        i_brand,
        i_category,
        ss_quantity,
        ss_net_paid,
        concat_ws(' ',
            c_first_name,
            c_last_name,
            lower(c_email_address),
            replace(c_login, '-', ''),
            s_store_name,
            substring(s_city, 1, 3),
            i_product_name,
            i_brand,
            i_category,
            i_item_desc
        ) AS full_str,
        length(concat_ws(' ',
            c_first_name,
            c_last_name,
            lower(c_email_address),
            replace(c_login, '-', ''),
            s_store_name,
            substring(s_city, 1, 3),
            i_product_name,
            i_brand,
            i_category,
            i_item_desc
        )) AS full_len,
        length(regexp_replace(lower(concat_ws(' ', c_first_name, c_last_name, i_product_name, i_item_desc)), '[^aeiou]', '')) AS vowel_cnt,
        length(regexp_replace(concat_ws(' ', c_first_name, c_last_name, c_email_address, c_login, s_store_name, i_product_name, i_item_desc), '\\D', '')) AS digit_cnt,
        reverse(concat_ws(' ', c_first_name, c_last_name, c_email_address, c_login, s_store_name, i_product_name, i_item_desc)) AS reversed_str,
        cardinality(split(regexp_replace(concat_ws(' ', c_first_name, c_last_name, c_email_address, c_login, s_store_name, i_product_name, i_item_desc), '\\s+', ' '), '\\s+')) AS word_cnt,
        regexp_extract(c_email_address, '@(.+)$') AS email_domain,
        substring(c_login, 1, 3) AS login_prefix,
        lower(s_store_name) AS store_name_lower,
        upper(i_category) AS category_upper
    FROM sales_join
)
SELECT
    s_store_name,
    s_city,
    count(*) AS sales_cnt,
    sum(full_len) AS total_len,
    avg(full_len) AS avg_len,
    sum(vowel_cnt) AS total_vowels,
    avg(vowel_cnt) AS avg_vowels,
    sum(digit_cnt) AS total_digits,
    avg(digit_cnt) AS avg_digits,
    avg(word_cnt) AS avg_word_cnt,
    approx_percentile(full_len, 0.5) AS median_len,
    max(email_domain) AS sample_email_domain,
    min(login_prefix) AS min_login_prefix
FROM metrics
GROUP BY s_store_name, s_city
ORDER BY avg_len DESC
LIMIT 10
