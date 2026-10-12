WITH item_words AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        LOWER(i.i_product_name) AS lower_name,
        REGEXP_REPLACE(i.i_product_name, '[^A-Za-z0-9]', ' ') AS cleaned_name,
        SPLIT(REGEXP_REPLACE(i.i_product_name, '[^A-Za-z0-9]', ' '), ' ') AS words_array,
        i.i_brand,
        i.i_color,
        REGEXP_EXTRACT(i.i_item_id, '(\\d+)', 1) AS item_id_numeric
    FROM
        item i
),
exploded_words AS (
    SELECT
        iw.i_item_sk,
        iw.i_item_id,
        iw.item_id_numeric,
        TRIM(w) AS word,
        iw.i_brand,
        iw.i_color
    FROM
        item_words iw
    CROSS JOIN UNNEST(iw.words_array) AS t(w)
    WHERE TRIM(w) <> ''
),
sales_detail AS (
    SELECT
        ew.word,
        ew.i_item_id,
        ew.item_id_numeric,
        ew.i_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        i.i_brand,
        i.i_color,
        d.d_year
    FROM
        exploded_words ew
    JOIN
        catalog_sales cs ON cs.cs_item_sk = ew.i_item_sk
    JOIN
        date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    JOIN
        item i ON i.i_item_sk = ew.i_item_sk
    WHERE
        d.d_year = 2001
),
sales_agg AS (
    SELECT
        word,
        MIN(item_id_numeric) AS min_item_id_numeric,
        MAX(item_id_numeric) AS max_item_id_numeric,
        COUNT(DISTINCT i_item_sk) AS distinct_items,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        MIN(i_brand) AS brand,
        MIN(i_color) AS color,
        cs_promo_sk,
        cs_call_center_sk
    FROM
        sales_detail
    GROUP BY
        word,
        cs_promo_sk,
        cs_call_center_sk
),
promotion_extracted AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        LOWER(p.p_promo_name) AS promo_name_lc,
        UPPER(p.p_promo_name) AS promo_name_uc,
        REGEXP_REPLACE(p.p_promo_name, '\\s+', '_') AS promo_underscored,
        LENGTH(p.p_promo_name) AS promo_len
    FROM
        promotion p
),
call_center_extracted AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_hours,
        cc.cc_manager,
        LOWER(cc.cc_name) AS cc_name_lc,
        SUBSTR(cc.cc_hours, 1, 5) AS hours_prefix,
        LENGTH(cc.cc_manager) AS manager_len
    FROM
        call_center cc
)
SELECT
    sa.word,
    TRIM(sa.word) AS trimmed_word,
    LENGTH(sa.word) AS word_len,
    REVERSE(sa.word) AS word_rev,
    UPPER(sa.word) AS word_up,
    SUBSTR(sa.brand, 1, 3) AS brand_prefix,
    CONCAT_WS('_', sa.brand, sa.color) AS brand_color,
    REPLACE(CONCAT_WS('_', sa.brand, sa.color), '-', '_') AS brand_color_clean,
    sa.distinct_items,
    sa.total_quantity,
    sa.total_sales,
    format('%,.2f', sa.total_sales) AS total_sales_formatted,
    sa.total_discount,
    sa.min_item_id_numeric,
    sa.max_item_id_numeric,
    pe.promo_name_lc,
    pe.promo_underscored,
    pe.promo_len AS promo_name_len,
    ccx.cc_name_lc,
    ccx.hours_prefix,
    ccx.manager_len,
    ROW_NUMBER() OVER (PARTITION BY sa.brand ORDER BY sa.total_sales DESC) AS brand_rank,
    SUM(sa.total_sales) OVER (PARTITION BY sa.brand) AS brand_total_sales
FROM
    sales_agg sa
LEFT JOIN
    promotion_extracted pe ON pe.p_promo_sk = sa.cs_promo_sk
LEFT JOIN
    call_center_extracted ccx ON ccx.cc_call_center_sk = sa.cs_call_center_sk
ORDER BY
    brand_total_sales DESC,
    sa.total_sales DESC
LIMIT 200
