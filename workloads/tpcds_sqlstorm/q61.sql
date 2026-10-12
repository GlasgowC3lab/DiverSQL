WITH base_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        d.d_date,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_size,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cc.cc_call_center_id,
        s.s_store_id,
        s.s_store_name,
        s.s_division_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON s.s_division_id = cc.cc_division
    WHERE ss.ss_net_paid > 0
),
desc_words AS (
    SELECT
        bs.ss_ticket_number,
        bs.s_store_id,
        bs.i_item_desc,
        w.word,
        length(w.word) AS word_len
    FROM base_sales bs
    LEFT JOIN UNNEST(split(bs.i_item_desc, '\\s+')) AS w(word) ON TRUE
),
desc_stats AS (
    SELECT
        ss_ticket_number,
        max(word_len) AS max_word_len,
        min(word_len) AS min_word_len,
        count(word) AS word_cnt
    FROM desc_words
    GROUP BY ss_ticket_number
)
SELECT
    bs.ss_ticket_number,
    bs.s_store_id,
    bs.c_customer_id,
    concat(upper(substr(bs.c_first_name,1,1)), lower(substr(bs.c_last_name,1,1))) AS name_initials,
    split(bs.c_email_address, '@')[1] AS email_user,
    split(bs.c_email_address, '@')[2] AS email_domain,
    bs.i_product_name,
    regexp_replace(bs.i_product_name, '[^A-Za-z0-9 ]', '') AS product_name_clean,
    upper(regexp_replace(bs.i_product_name, '[^A-Za-z0-9 ]', '')) AS product_name_upper,
    length(regexp_replace(bs.i_product_name, '[^A-Za-z0-9 ]', '')) AS product_name_len,
    substr(bs.i_product_name, 1, 10) AS product_name_prefix_10,
    reverse(bs.i_product_name) AS product_name_reversed,
    regexp_extract(bs.i_product_name, '([A-Z]{2,})', 1) AS product_name_caps_seq,
    trim(bs.i_product_name) AS product_name_trimmed,
    cardinality(split(bs.i_item_desc, '\\s+')) AS desc_word_cnt,
    array_join(split(bs.i_item_desc, '\\s+'), '|') AS desc_word_array_pipe,
    length(regexp_replace(bs.i_item_desc, '\\s+', '')) AS desc_char_cnt_no_spaces,
    regexp_like(bs.i_item_desc, '\\b[A-Z][a-z]+\\b') AS has_title_case_word,
    strpos(lower(bs.i_item_desc), 'discount') AS discount_word_position,
    ds.word_cnt AS product_desc_word_cnt,
    ds.max_word_len AS product_desc_max_word_len,
    ds.min_word_len AS product_desc_min_word_len,
    concat_ws('|', bs.cc_call_center_id, bs.s_store_id, bs.c_customer_id, date_format(bs.d_date, '%Y%m%d')) AS composite_key,
    row_number() OVER (PARTITION BY bs.c_customer_id ORDER BY bs.ss_net_paid DESC) AS cust_sales_rank,
    sum(bs.ss_net_paid) OVER (PARTITION BY bs.s_store_id) AS store_total_net_paid,
    replace(lower(bs.i_color), ' ', '_') AS color_underscored,
    translate(bs.i_size, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') AS size_lowercase,
    regexp_replace(bs.i_product_name, '^(.{5}).*', '$1') AS product_name_prefix_5,
    format('%s-%s-%s', bs.s_store_id, bs.i_item_id, bs.c_customer_id) AS formatted_id
FROM base_sales bs
JOIN desc_stats ds ON bs.ss_ticket_number = ds.ss_ticket_number
WHERE bs.c_email_address IS NOT NULL
ORDER BY bs.s_store_id, bs.ss_ticket_number
LIMIT 100
