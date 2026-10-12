WITH processed_customers AS (
    SELECT
        c.c_customer_sk,
        concat(lower(c.c_first_name), '.', lower(c.c_last_name), '@', split_part(c.c_email_address, '@', 2)) AS normalized_email,
        length(c.c_email_address) AS email_len,
        split_part(c.c_email_address, '@', 2) AS email_domain,
        replace(c.c_first_name, ' ', '_') AS sanitized_first_name,
        translate(c.c_last_name, 'AEIOUaeiou', '**********') AS vowel_masked_last_name,
        concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
        length(concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name)) AS full_name_len
    FROM customer c
),
processed_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        lower(i.i_product_name) AS product_name_lower,
        regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]', '') AS product_name_alphanum,
        split(i.i_product_name, ' ') AS product_name_tokens,
        cardinality(split(i.i_product_name, ' ')) AS product_name_token_count,
        substr(i.i_product_name, 1, 10) AS product_name_prefix,
        substr(i.i_product_name, -10) AS product_name_suffix,
        replace(i.i_color, ' ', '') AS color_no_space,
        translate(i.i_size, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') AS size_lower,
        length(i.i_product_name) AS product_name_len
    FROM item i
),
store_full_address AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        concat_ws(' ',
            s.s_street_number,
            s.s_street_name,
            s.s_street_type,
            coalesce(s.s_suite_number, ''),
            s.s_city,
            s.s_state,
            s.s_zip) AS full_address,
        upper(concat_ws(' ', s.s_city, s.s_state)) AS city_state_upper,
        length(concat_ws(' ', s.s_city, s.s_state)) AS city_state_len,
        regexp_replace(concat_ws(' ', s.s_street_name, s.s_street_type), '\\s+', ' ') AS normalized_street
    FROM store s
),
joined_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        pc.product_name_len,
        pc.product_name_token_count,
        pc.product_name_prefix,
        pc.product_name_suffix,
        cu.email_len,
        cu.full_name_len,
        addr.city_state_len,
        ss.ss_net_paid * pc.product_name_len AS weighted_paid_by_name_len
    FROM store_sales ss
    JOIN processed_items pc ON ss.ss_item_sk = pc.i_item_sk
    JOIN processed_customers cu ON ss.ss_customer_sk = cu.c_customer_sk
    JOIN store_full_address addr ON ss.ss_store_sk = addr.s_store_sk
    WHERE ss.ss_net_paid > 0
),
final_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        addr.s_store_name AS store_name,
        sum(js.weighted_paid_by_name_len) AS total_weighted_paid,
        avg(js.ss_net_paid) AS avg_net_paid,
        avg(js.email_len) AS avg_email_len,
        avg(js.full_name_len) AS avg_full_name_len,
        count(DISTINCT js.ss_customer_sk) AS distinct_customers,
        sum(js.ss_quantity) AS total_quantity,
        approx_distinct(js.product_name_prefix) AS distinct_product_prefixes,
        array_agg(DISTINCT js.product_name_suffix) FILTER (WHERE js.product_name_suffix IS NOT NULL) AS sample_suffixes
    FROM joined_sales js
    JOIN date_dim d ON js.ss_sold_date_sk = d.d_date_sk
    JOIN store_full_address addr ON js.ss_store_sk = addr.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, addr.s_store_name
    HAVING sum(js.ss_net_paid) > 100000
)
SELECT
    year,
    month_seq,
    store_name,
    total_weighted_paid,
    avg_net_paid,
    avg_email_len,
    avg_full_name_len,
    distinct_customers,
    total_quantity,
    distinct_product_prefixes,
    sample_suffixes
FROM final_agg
ORDER BY total_weighted_paid DESC
LIMIT 20
