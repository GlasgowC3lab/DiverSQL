WITH raw_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        s.s_store_id,
        s.s_store_name,
        s.s_street_number,
        s.s_street_name,
        s.s_street_type,
        s.s_suite_number,
        s.s_city,
        s.s_state,
        s.s_zip,
        c.c_customer_id,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        i.i_product_name,
        i.i_item_desc,
        d.d_year
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_quantity > 0
),
sales_with_words AS (
    SELECT
        rs.*,
        regexp_replace(i_product_name, '[^a-zA-Z0-9 ]', '') AS product_name_clean,
        replace(lower(regexp_replace(i_product_name, '[^a-zA-Z0-9 ]', '')), ' ', '_') AS product_name_underscored,
        substr(i_product_name, 1, 10) AS product_name_prefix,
        regexp_split(i_item_desc, '\\s+') AS desc_word_array,
        cardinality(regexp_split(i_item_desc, '\\s+')) AS desc_word_count,
        lower(trim(c_email_address)) AS email_normalized,
        concat_ws(' ', c_first_name, c_last_name) AS customer_full_name,
        lower(concat_ws(' ', c_first_name, c_last_name)) AS customer_name_normalized,
        format('Store %s - %s', s_store_id, s_store_name) AS store_label,
        concat_ws(', ', concat_ws(' ', s_street_number, s_street_name, s_street_type), s_suite_number, concat_ws(' ', s_city, s_state, s_zip)) AS store_full_address,
        format('%s_%s', s_store_id, d_year) AS store_year_key
    FROM raw_sales rs
),
exploded AS (
    SELECT
        sw.*,
        word
    FROM sales_with_words sw
    CROSS JOIN UNNEST(sw.desc_word_array) AS t(word)
    WHERE word <> ''
),
aggregated AS (
    SELECT
        store_year_key,
        store_label,
        store_full_address,
        email_normalized,
        customer_name_normalized,
        sum(ss_quantity) AS total_quantity,
        sum(ss_net_paid) AS total_sales,
        avg(desc_word_count) AS avg_desc_word_count,
        array_join(array_agg(DISTINCT product_name_underscored ORDER BY product_name_underscored), ',') AS product_list_underscored,
        array_join(array_agg(DISTINCT lower(word) ORDER BY lower(word)), ',') AS word_list
    FROM exploded
    GROUP BY
        store_year_key,
        store_label,
        store_full_address,
        email_normalized,
        customer_name_normalized
)
SELECT *
FROM aggregated
