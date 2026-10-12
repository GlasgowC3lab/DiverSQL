WITH sales_data AS (
    SELECT
        i.i_category,
        date_trunc('month', CAST(d.d_date AS timestamp)) AS month_start,
        ss.ss_net_paid,
        ss.ss_quantity,
        i.i_product_name,
        i.i_item_desc,
        upper(p.p_promo_name) AS promo_name_upper,
        p.p_promo_name AS promo_name_raw,
        s.s_store_name AS store_name,
        s.s_manager AS store_manager
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
),
aggregated AS (
    SELECT
        i_category,
        month_start,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        AVG(LENGTH(i_product_name)) AS avg_name_len,
        AVG(LENGTH(regexp_replace(lower(i_product_name), '[^aeiou]', ''))) AS avg_vowel_cnt,
        AVG(CARDINALITY(split(i_product_name, '\\s+'))) AS avg_name_word_cnt,
        MAX(LENGTH(i_item_desc)) AS max_desc_len,
        MIN(reverse(i_product_name)) AS min_name_rev,
        any_value(promo_name_upper) AS promo_name_upper,
        any_value(promo_name_raw) AS promo_name_raw,
        any_value(store_name) AS store_name,
        any_value(store_manager) AS store_manager
    FROM sales_data
    GROUP BY i_category, month_start
),
ranked AS (
    SELECT
        i_category,
        month_start,
        total_net_paid,
        total_quantity,
        avg_name_len,
        avg_vowel_cnt,
        avg_name_word_cnt,
        max_desc_len,
        min_name_rev,
        promo_name_upper,
        promo_name_raw,
        store_name,
        store_manager,
        array_join(transform(split(promo_name_raw, '\\s+'), w -> reverse(w)), ' ') AS promo_name_words_rev,
        array_join(transform(split(store_name, '\\s+'), w -> substr(w, 1, 1)), '') AS store_initials,
        length(store_name) AS store_name_len,
        lower(store_manager) AS store_manager_lc,
        replace(format_datetime(month_start, '%Y-%m-%d'), '-', '') AS month_key,
        row_number() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS rn
    FROM aggregated
)
SELECT
    i_category,
    month_start,
    total_net_paid,
    total_quantity,
    avg_name_len,
    avg_vowel_cnt,
    avg_name_word_cnt,
    max_desc_len,
    min_name_rev,
    promo_name_upper,
    promo_name_words_rev,
    store_initials,
    store_name_len,
    store_manager_lc,
    month_key,
    rn
FROM ranked
WHERE rn <= 5
ORDER BY i_category, rn
