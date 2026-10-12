WITH joined_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_year,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_class,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_color,
        i.i_size,
        i.i_formulation,
        ss.ss_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid
    FROM catalog_sales cs
    JOIN store_sales ss ON cs.cs_order_number = ss.ss_ticket_number
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
)
SELECT
    d_year,
    cc_call_center_sk,
    concat_ws(' - ', cc_name, cc_manager) AS call_center_info,
    upper(cc_manager) AS manager_upper,
    length(cc_name) AS call_center_name_len,
    replace(lower(cc_manager), ' ', '_') AS manager_underscored,
    CASE WHEN strpos(cc_name, ' ') > 0 THEN 'HAS SPACE' ELSE 'NO SPACE' END AS cc_name_space_flag,
    concat(cc_name, ': ', cc_class) AS cc_with_class,
    regexp_replace(cc_class, '[^A-Za-z]', '') AS cc_class_alnum,
    substr(cc_name, 1, 10) AS cc_name_prefix,
    cardinality(split(cc_name, ' ')) AS cc_name_word_cnt,
    i_product_name_clean,
    length(i_product_name_clean) AS product_name_len,
    lower(i_product_name_clean) AS product_name_lower,
    replace(i_product_name_clean, ' ', '_') AS product_name_underscored,
    regexp_replace(i_product_name_clean, '[^A-Za-z0-9]', '') AS product_name_alnum,
    substr(i_product_name_clean, 1, 12) AS product_name_prefix,
    strpos(i_product_name_clean, ' ') AS first_space_pos,
    cardinality(split(i_product_name_clean, ' ')) AS product_word_cnt,
    CASE WHEN regexp_like(i_product_name_clean, '\\d') THEN 'YES' ELSE 'NO' END AS product_has_digit,
    reverse(i_product_name_clean) AS product_name_rev,
    format('Product %s (%s)', i_product_name_clean, i_brand) AS formatted_product,
    concat_ws(', ', s_store_name, s_city, s_state) AS store_location,
    lower(s_store_name) AS store_name_lower,
    length(s_store_name) AS store_name_len,
    replace(s_store_name, ' ', '-') AS store_name_hyphened,
    regexp_replace(s_store_name, '[^A-Za-z]', '') AS store_name_alpha,
    cardinality(split(s_store_name, ' ')) AS store_name_word_cnt,
    sum(cs_quantity) AS total_cs_quantity,
    sum(ss_quantity) AS total_ss_quantity,
    sum(cs_net_paid) AS total_cs_net_paid,
    sum(ss_net_paid) AS total_ss_net_paid,
    sum(cs_quantity + ss_quantity) AS total_quantity,
    sum(cs_net_paid + ss_net_paid) AS total_net_paid,
    count(*) AS sales_rows
FROM (
    SELECT
        d_year,
        cc_call_center_sk,
        cc_name,
        cc_manager,
        cc_class,
        i_product_name,
        i_brand,
        s_store_name,
        s_city,
        s_state,
        cs_quantity,
        cs_net_paid,
        ss_quantity,
        ss_net_paid,
        trim(regexp_replace(i_product_name, '\\s+', ' ')) AS i_product_name_clean
    FROM joined_sales
) t
GROUP BY
    d_year,
    cc_call_center_sk,
    cc_name,
    cc_manager,
    cc_class,
    i_product_name_clean,
    i_brand,
    s_store_name,
    s_city,
    s_state
HAVING
    sum(cs_net_paid) > 1000
ORDER BY
    total_net_paid DESC
LIMIT 100
