WITH
item_strings AS (
    SELECT
        i_item_sk,
        i_product_name,
        length(i_product_name) AS product_name_len,
        lower(i_product_name) AS product_name_lc,
        regexp_replace(i_product_name, '[aeiouAEIOU]', '') AS product_name_no_vowels,
        cardinality(split(i_product_name, ' ')) AS product_name_word_cnt,
        regexp_extract(i_product_name, '([0-9]+)', 1) AS first_number_seq,
        regexp_replace(i_product_name, '[^0-9]', '') AS numbers_concat,
        regexp_replace(i_product_name, '([A-Z])', '_$1') AS underscore_before_caps
    FROM item
),
store_strings AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        concat_ws(' - ', s_store_name, s_city, s_state) AS store_full_label,
        lower(s_store_name) AS store_name_lc,
        regexp_replace(s_store_name, '\\s+', '') AS store_name_nospace,
        length(s_store_name) AS store_name_len,
        cardinality(split(s_store_name, ' ')) AS store_name_word_cnt
    FROM store
),
call_center_strings AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_city,
        cc_state,
        concat_ws(' | ', cc_name, cc_city, cc_state) AS cc_full_label,
        lower(cc_name) AS cc_name_lc,
        regexp_replace(cc_name, '\\s+', '') AS cc_name_nospace,
        length(cc_name) AS cc_name_len,
        cardinality(split(cc_name, ' ')) AS cc_name_word_cnt
    FROM call_center
),
store_sales_item AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_customer_sk,
        i.product_name_len,
        i.product_name_word_cnt,
        i.first_number_seq,
        i.numbers_concat,
        i.product_name_no_vowels,
        i.underscore_before_caps
    FROM store_sales ss
    JOIN item_strings i ON ss.ss_item_sk = i.i_item_sk
),
store_agg AS (
    SELECT
        ssi.ss_store_sk AS store_sk,
        SUM(ssi.ss_net_profit) AS total_net_profit,
        SUM(ssi.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ssi.ss_customer_sk) AS distinct_customers,
        MAX(ssi.product_name_len) AS max_product_name_len,
        MIN(ssi.first_number_seq) AS min_number_seq,
        array_agg(DISTINCT ssi.product_name_no_vowels) AS distinct_no_vowel_names,
        array_join(array_agg(DISTINCT ssi.underscore_before_caps), ',') AS underscore_caps_concat
    FROM store_sales_item ssi
    GROUP BY ssi.ss_store_sk
),
final_result AS (
    SELECT
        sa.store_sk,
        sa.total_net_profit,
        sa.total_quantity,
        sa.distinct_customers,
        sa.max_product_name_len,
        sa.min_number_seq,
        sa.distinct_no_vowel_names,
        sa.underscore_caps_concat,
        ss.store_full_label,
        ss.store_name_lc,
        ss.store_name_nospace,
        ss.store_name_len,
        ss.store_name_word_cnt
    FROM store_agg sa
    JOIN store_strings ss ON sa.store_sk = ss.s_store_sk
)
SELECT *
FROM final_result
