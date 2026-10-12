WITH normalized_items AS (
    SELECT i_item_sk,
           lower(i_product_name) AS product_name_lc,
           regexp_replace(i_product_name, '[^a-z0-9 ]', '') AS product_name_clean,
           split(regexp_replace(i_product_name, '[^a-z0-9 ]', ''), ' ') AS product_name_words,
           cardinality(array_distinct(split(regexp_replace(i_product_name, '[^a-z0-9 ]', ''), ' '))) AS distinct_word_count,
           length(i_product_name) AS product_name_len,
           array_join(array_sort(array_distinct(split(regexp_replace(i_product_name, '[^a-z0-9 ]', ''), ' '))), '-') AS product_name_signature,
           i_item_desc
    FROM item
),
store_info AS (
    SELECT s_store_sk,
           concat_ws(', ', s_street_number, s_street_name, s_city, s_state, s_zip) AS store_address,
           lower(s_store_name) AS store_name_lc,
           length(s_store_name) AS store_name_len,
           trim(s_hours) AS store_hours_trim
    FROM store
),
sales_joined AS (
    SELECT ss.ss_sold_date_sk,
           ss.ss_ticket_number,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           si.store_address,
           i.i_item_sk,
           ni.product_name_clean,
           ni.distinct_word_count,
           ni.product_name_len,
           ni.product_name_signature,
           dd.d_year,
           dd.d_month_seq,
           dd.d_week_seq,
           CASE WHEN regexp_like(ni.product_name_clean, '\\bsize\\b') THEN 'ContainsSize' ELSE 'NoSize' END AS size_flag
    FROM store_sales ss
    JOIN store_info si ON ss.ss_store_sk = si.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN normalized_items ni ON i.i_item_sk = ni.i_item_sk
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE ss.ss_net_paid > 0
)
SELECT 
    store_address,
    size_flag,
    sum(quantity) AS total_quantity,
    sum(net_paid) AS total_net_paid,
    avg(product_name_len) AS avg_product_name_len,
    avg(distinct_word_count) AS avg_distinct_word_count,
    count(DISTINCT i_item_sk) AS distinct_items_sold,
    max(product_name_len) AS max_product_name_len,
    min(product_name_len) AS min_product_name_len,
    array_join(array_agg(DISTINCT product_name_clean), ', ') AS distinct_product_names
FROM sales_joined
GROUP BY store_address, size_flag
