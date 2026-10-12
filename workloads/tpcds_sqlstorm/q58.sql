WITH cleaned_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        trim(i.i_item_desc) AS trimmed_desc,
        regexp_replace(i.i_item_desc, '\\s+', ' ') AS normalized_desc,
        split(i.i_item_desc, '\\s+') AS words,
        cardinality(split(i.i_item_desc, '\\s+')) AS word_count,
        lower(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS alphanum_desc,
        length(i.i_item_desc) AS desc_len
    FROM item i
),
promo_flags AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        lower(p.p_promo_name) AS lower_name,
        regexp_like(p.p_promo_name, '(?i)discount|sale') AS is_discount,
        regexp_extract(p.p_promo_name, '(?i)(discount|sale)') AS discount_word,
        concat_ws('|', p.p_channel_email, p.p_channel_tv, p.p_channel_radio) AS channels_concat,
        length(concat_ws('|', p.p_channel_email, p.p_channel_tv, p.p_channel_radio)) AS channels_len
    FROM promotion p
),
sales_aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_state,
        cc.cc_city,
        cc.cc_zip,
        ci.i_item_sk,
        ci.desc_len,
        ci.word_count,
        ci.alphanum_desc,
        pf.is_discount,
        pf.discount_word,
        sum(cs.cs_net_paid) AS total_net_paid,
        avg(cs.cs_ext_discount_amt) AS avg_ext_discount,
        count(distinct cs.cs_order_number) AS uniq_orders,
        array_join(array_agg(distinct ci.i_product_name), ',') AS product_list,
        cardinality(array_agg(distinct ci.i_product_name)) AS product_count,
        count(*) AS sales_rows,
        length(concat_ws('_', lower(cc.cc_name), ci.alphanum_desc)) AS combined_len,
        regexp_replace(concat_ws('_', lower(cc.cc_name), ci.alphanum_desc), '^(.{0,20}).*$', '$1') AS combined_prefix
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN cleaned_items ci ON cs.cs_item_sk = ci.i_item_sk
    LEFT JOIN promo_flags pf ON cs.cs_promo_sk = pf.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cc.cc_name IS NOT NULL
      AND ci.i_item_desc IS NOT NULL
    GROUP BY
        d.d_year,
        d.d_month_seq,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_state,
        cc.cc_city,
        cc.cc_zip,
        ci.i_item_sk,
        ci.desc_len,
        ci.word_count,
        ci.alphanum_desc,
        pf.is_discount,
        pf.discount_word
)
SELECT
    d_year,
    d_month_seq,
    lower(trim(cc_name)) AS normalized_cc_name,
    length(cc_name) AS cc_name_len,
    substr(cc_manager, 1, 10) AS manager_prefix,
    concat_ws('-', cc_state, cc_city, cc_zip) AS location_code,
    product_count,
    total_net_paid,
    avg_ext_discount,
    uniq_orders,
    sales_rows,
    combined_len,
    combined_prefix,
    is_discount,
    discount_word,
    upper(discount_word) AS discount_word_upper,
    length(discount_word) AS discount_word_len,
    regexp_like(product_list, '.*[A-Z]{3}.*') AS product_list_has_three_caps,
    replace(product_list, ',', '') 
FROM sales_aggregated
