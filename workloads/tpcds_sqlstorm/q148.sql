WITH base AS (
    SELECT
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_item_sk,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        st.s_store_name,
        d.d_year
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
)
SELECT
    d_year,
    count(*) AS total_sales,
    approx_distinct(lower(i_product_name)) AS uniq_product_names,
    sum(ss_quantity) AS total_quantity,
    sum(ss_ext_sales_price) AS total_revenue,
    avg(length(concat_ws(' ', i_product_name, i_item_desc))) AS avg_full_desc_len,
    avg(length(trim(i_item_desc))) AS avg_trim_desc_len,
    avg(length(replace(i_item_desc, ' ', ''))) AS avg_desc_no_spaces_len,
    max(cardinality(split(i_item_desc, ' '))) AS max_token_count,
    sum(CASE WHEN regexp_like(i_item_desc, '\\d{2}') THEN 1 ELSE 0 END) AS sales_with_two_digit_numbers,
    array_join(array_agg(DISTINCT split(c_email_address, '@')[2]), ', ') AS email_domains,
    sum(CASE WHEN regexp_like(c_email_address, '\\.com$') THEN 1 ELSE 0 END) AS com_email_count,
    max(reverse(s_store_name)) AS rev_store_name_max,
    avg(length(trim(s_store_name))) AS avg_trim_store_name_len,
    approx_distinct(trim(s_store_name)) AS uniq_trimmed_store_names,
    sum(CASE WHEN p.p_promo_name IS NOT NULL AND regexp_like(p.p_promo_name, '(?i)promo') THEN 1 ELSE 0 END) AS promo_name_match_count,
    avg(length(regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', ''))) AS avg_clean_desc_len,
    avg(length(replace(i_color, ' ', '_'))) AS avg_color_underscored_len,
    avg(length(translate(i_color, 'aeiou', 'AEIOU'))) AS avg_color_vowel_upper_len,
    avg(length(format('Customer %s %s at %s', c_first_name, c_last_name, s_store_name))) AS avg_formatted_str_len,
    sum(CASE WHEN regexp_like(i_item_desc, '(?i)large') THEN 1 ELSE 0 END) AS large_desc_count,
    avg(length(regexp_replace(replace(i_item_desc, ' ', '-'), '[^A-Za-z0-9-]', ''))) AS avg_hyphenated_clean_desc_len
FROM base
LEFT JOIN promotion p ON base.ss_item_sk = p.p_item_sk
GROUP BY d_year
ORDER BY d_year DESC
