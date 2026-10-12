WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_brand,
        i.i_color,
        i.i_size,
        i.i_class,
        i.i_category,
        i.i_manufact,
        s.s_store_name,
        s.s_city,
        s.s_state,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_login,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
),
ranked AS (
    SELECT
        *,
        row_number() OVER (PARTITION BY i_item_sk, d_year, d_month_seq ORDER BY ss_quantity DESC) AS rn
    FROM base_sales
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.rn,
    r.i_item_id,
    r.i_product_name,
    concat_ws(' - ', r.s_store_name, r.s_city, r.s_state) AS store_location,
    upper(r.c_first_name) || ' ' || upper(r.c_last_name) AS customer_name,
    lower(r.c_email_address) AS email_lower,
    trim(r.i_brand) AS brand_trimmed,
    substr(r.i_product_name, 1, 15) AS product_name_prefix,
    replace(r.i_product_name, ' ', '_') AS product_name_underscored,
    regexp_replace(r.i_product_name, '[AEIOUaeiou]', '*') AS product_name_masked,
    substr(r.i_item_desc, 1, 30) AS item_desc_head,
    length(r.i_item_desc) AS item_desc_len,
    regexp_extract(r.i_item_desc, '\\b([A-Za-z]{5})\\b', 1) AS first_5letter_word,
    regexp_replace(r.i_item_desc, '\\s+', ' ') AS item_desc_normalized,
    CASE WHEN regexp_like(r.i_item_desc, '\\bdiscount\\b') THEN 'Discounted' ELSE 'Regular' END AS discount_flag,
    (strpos(r.i_color, 'Red') > 0) AS has_red_color,
    cardinality(split(regexp_replace(r.i_item_desc, '[^A-Za-z]', ' '), ' ')) AS word_count,
    array_join(array_agg(DISTINCT r.i_color) OVER (PARTITION BY r.i_item_sk), ',') AS colors_aggregate,
    sum(r.ss_quantity) OVER (PARTITION BY r.i_item_sk) AS total_quantity_item,
    sum(r.ss_net_paid) OVER (PARTITION BY r.i_item_sk) AS total_net_paid_item,
    format('Item %s (%s) sold in %s-%s', r.i_item_id, r.i_product_name, r.d_year, r.d_month_seq) AS summary,
    concat('Brand:', r.i_brand, '|Class:', r.i_class, '|Category:', r.i_category) AS brand_class_category
FROM ranked r
WHERE r.rn <= 5
ORDER BY r.d_year, r.d_month_seq, r.rn
