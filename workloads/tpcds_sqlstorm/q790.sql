WITH cleaned_sales AS (
    SELECT
        s.s_store_id,
        d.d_date,
        lower(trim(s.s_store_name)) AS store_name_clean,
        i.i_item_sk,
        i.i_product_name,
        regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]', '') AS product_name_alnum,
        substr(i.i_product_name, 1, 3) AS product_name_prefix,
        length(i.i_product_name) AS product_name_len,
        length(regexp_replace(i.i_product_name, '(?i)[^a-z]', '')) AS product_name_alpha_len,
        lower(i.i_product_name) AS product_name_lower,
        ss.ss_quantity,
        ss.ss_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
      AND i.i_color IS NOT NULL
      AND i.i_product_name LIKE '%COFFEE%'
)
SELECT
    s_store_id AS store_id,
    d_date,
    store_name_clean,
    array_join(array_agg(DISTINCT product_name_alnum), ', ') AS distinct_clean_product_names,
    sum(ss_quantity) AS total_quantity_sold,
    sum(ss_net_paid) AS total_net_paid,
    max(product_name_len) AS max_product_name_len,
    avg(product_name_alpha_len) AS avg_alpha_len,
    count(DISTINCT i_item_sk) AS distinct_items_sold,
    array_join(array_sort(array_distinct(array_agg(product_name_prefix))), '|') AS product_prefixes_concat,
    sum(length(product_name_lower) - length(replace(product_name_lower, 'e', ''))) AS total_e_count,
    sum(length(regexp_replace(product_name_lower, '[^aeiou]', ''))) AS total_vowel_count
FROM cleaned_sales
GROUP BY s_store_id, d_date, store_name_clean
ORDER BY total_net_paid DESC
LIMIT 100
