WITH base AS (
    SELECT
        ss.ss_store_sk,
        upper(trim(s.s_city)) AS store_city,
        upper(trim(concat_ws(' ', c.c_first_name, c.c_last_name))) AS cust_full_name,
        lower(regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]', '')) AS clean_product_name,
        reverse(i.i_product_name) AS rev_product_name,
        length(i.i_product_name) AS product_name_len,
        concat(substring(i.i_product_name FROM 1 FOR 3), '-', substring(i.i_product_name FROM length(i.i_product_name) - 2)) AS product_name_abbrev,
        concat('SKU-', lpad(CAST(i.i_item_sk AS varchar), 8, '0')) AS sku,
        replace(lower(i.i_product_name), ' ', '-') AS product_slug,
        substring(i.i_item_desc FROM 1 FOR 10) AS item_desc_prefix,
        reverse(i.i_color) AS rev_color,
        regexp_extract(s.s_hours, '^(\\d{1,2}):\\d{2}', 1) AS store_start_hour,
        regexp_extract(s.s_hours, '(\\d{1,2}):\\d{2}$', 1) AS store_end_hour,
        cardinality(split(i.i_product_name, ' ')) AS product_word_count,
        array_max(transform(split(i.i_product_name, ' '), x -> length(x))) AS product_longest_word_len,
        concat_ws(' | ',
            upper(trim(concat_ws(' ', c.c_first_name, c.c_last_name))),
            upper(trim(s.s_city)),
            lower(regexp_replace(i.i_product_name, '[^a-zA-Z0-9 ]', ''))
        ) AS composite_key,
        d.d_date,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE i.i_product_name IS NOT NULL
      AND ss.ss_net_paid > 0
      AND regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{3}')
),
agg AS (
    SELECT
        ss_store_sk,
        store_city,
        cust_full_name,
        clean_product_name,
        rev_product_name,
        product_name_len,
        product_name_abbrev,
        sku,
        product_slug,
        item_desc_prefix,
        rev_color,
        store_start_hour,
        store_end_hour,
        product_word_count,
        product_longest_word_len,
        composite_key,
        CAST(d_date AS varchar) AS sale_date_str,
        sum(ss_net_paid) AS total_net_paid,
        sum(ss_net_profit) AS total_net_profit,
        count(*) AS sales_cnt
    FROM base
    GROUP BY
        ss_store_sk,
        store_city,
        cust_full_name,
        clean_product_name,
        rev_product_name,
        product_name_len,
        product_name_abbrev,
        sku,
        product_slug,
        item_desc_prefix,
        rev_color,
        store_start_hour,
        store_end_hour,
        product_word_count,
        product_longest_word_len,
        composite_key,
        d_date
)
SELECT
    ss_store_sk,
    store_city,
    cust_full_name,
    sale_date_str,
    clean_product_name,
    rev_product_name,
    product_name_len,
    product_name_abbrev,
    sku,
    product_slug,
    item_desc_prefix,
    rev_color,
    store_start_hour,
    store_end_hour,
    product_word_count,
    product_longest_word_len,
    composite_key,
    total_net_paid,
    total_net_profit,
    sales_cnt,
    row_number() OVER (PARTITION BY ss_store_sk ORDER BY total_net_profit DESC) AS store_product_rank
FROM agg
WHERE total_net_paid > 1000
ORDER BY total_net_paid DESC
LIMIT 100
