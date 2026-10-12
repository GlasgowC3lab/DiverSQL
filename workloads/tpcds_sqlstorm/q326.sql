WITH product_strings AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        lower(i.i_product_name) AS prod_name_lc,
        upper(i.i_product_name) AS prod_name_uc,
        length(i.i_product_name) AS prod_name_len,
        substr(i.i_product_name, 1, 5) AS prod_name_prefix,
        substr(i.i_product_name, -5) AS prod_name_suffix,
        reverse(i.i_product_name) AS prod_name_rev,
        replace(i.i_product_name, ' ', '_') AS prod_name_underscore,
        regexp_replace(i.i_product_name, '\\s+', '_') AS prod_name_snake,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word,
        regexp_extract(i.i_item_desc, '\\b([A-Za-z]{6,})\\b', 1) AS first_long_word_desc,
        replace(i.i_item_desc, '\n', ' ') AS item_desc_clean,
        cardinality(split(i.i_item_desc, '\\s+')) AS item_desc_word_count,
        array_join(split(i.i_item_desc, '\\s+'), '|') AS item_desc_pipe_joined,
        concat_ws(' ', i.i_brand, i.i_class, i.i_category, i.i_color, i.i_size, i.i_units) AS combined_features
    FROM item i
),
call_center_strings AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        lower(cc.cc_name) AS cc_name_lc,
        upper(cc.cc_name) AS cc_name_uc,
        length(cc.cc_name) AS cc_name_len,
        replace(cc.cc_hours, ':', '-') AS cc_hours_dash,
        regexp_replace(cc.cc_name, '[^A-Za-z]', '') AS cc_name_alpha,
        concat_ws(' | ', cc.cc_manager, cc.cc_market_manager) AS managers_concat,
        cardinality(split(cc.cc_manager, '\\s+')) AS manager_word_cnt,
        array_join(split(cc.cc_manager, '\\s+'), ',') AS manager_csv
    FROM call_center cc
),
store_strings AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        lower(s.s_store_name) AS store_name_lc,
        upper(s.s_store_name) AS store_name_uc,
        length(s.s_store_name) AS store_name_len,
        replace(s.s_hours, ':', '-') AS store_hours_dash,
        regexp_replace(s.s_store_name, '[^A-Za-z]', '') AS store_name_alpha,
        concat_ws(' | ', s.s_manager, s.s_market_manager) AS store_managers_concat,
        cardinality(split(s.s_manager, '\\s+')) AS store_manager_word_cnt,
        array_join(split(s.s_manager, '\\s+'), ',') AS store_manager_csv
    FROM store s
),
catalog_page_strings AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_description,
        lower(cp.cp_description) AS cp_desc_lc,
        upper(cp.cp_description) AS cp_desc_uc,
        length(cp.cp_description) AS cp_desc_len,
        cardinality(split(cp.cp_description, '\\s+')) AS cp_desc_word_cnt,
        array_join(split(cp.cp_description, '\\s+'), '|') AS cp_desc_pipe_joined,
        regexp_extract(cp.cp_description, '^([^\\.]+)', 1) AS first_sentence
    FROM catalog_page cp
),
web_page_strings AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        lower(wp.wp_url) AS url_lc,
        replace(wp.wp_url, 'https://', '') AS url_no_https,
        regexp_replace(wp.wp_url, 'https?://', '') AS url_no_proto,
        length(wp.wp_url) AS url_len,
        cardinality(split(wp.wp_url, '/')) AS url_path_segments,
        array_join(split(wp.wp_url, '/'), '|') AS url_path_pipe,
        regexp_extract(wp.wp_url, '([^/]+)\\.([a-z]{2,})$', 1) AS domain_part,
        regexp_extract(wp.wp_url, '([^/]+)\\.([a-z]{2,})$', 2) AS domain_tld
    FROM web_page wp
),
catalog_sales_strings AS (
    SELECT
        d.d_date,
        'catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        p.prod_name_snake,
        length(concat_ws(' - ', c.cc_name, cp.cp_description)) AS combined_desc_len,
        length(regexp_replace(concat_ws(' - ', c.cc_name, cp.cp_description), '[^eE]', '')) AS special_char_cnt,
        cardinality(split(concat_ws('_', p.prod_name_snake, replace(p.item_desc_clean, ' ', '_')), '_')) AS snake_word_cnt,
        length(concat(cp.cp_description, ' *** ', cp.cp_description)) AS double_len
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN product_strings p ON cs.cs_item_sk = p.i_item_sk
    JOIN call_center_strings c ON cs.cs_call_center_sk = c.cc_call_center_sk
    JOIN catalog_page_strings cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
),
store_sales_strings AS (
    SELECT
        d.d_date,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        p.prod_name_snake,
        length(concat_ws(' + ', s.s_store_name, p.i_product_name)) AS combined_desc_len,
        length(regexp_replace(concat_ws(' + ', s.s_store_name, p.i_product_name), '[^0-9]', '')) AS special_char_cnt,
        cardinality(split(concat_ws('_', replace(s.s_store_name, ' ', '_'), p.prod_name_snake), '_')) AS snake_word_cnt,
        length(concat(p.i_product_name, ' ### ', p.i_product_name)) AS double_len
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN product_strings p ON ss.ss_item_sk = p.i_item_sk
    JOIN store_strings s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
),
web_sales_strings AS (
    SELECT
        d.d_date,
        'web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        p.prod_name_snake,
        length(concat_ws(' | ', wp.url_lc, p.i_product_name)) AS combined_desc_len,
        length(regexp_replace(wp.url_lc, '[^a]', '')) AS special_char_cnt,
        cardinality(split(concat_ws('_', wp.url_no_proto, p.prod_name_snake), '_')) AS snake_word_cnt,
        length(concat(wp.url_lc, ' :: ', wp.url_lc)) AS double_len
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN product_strings p ON ws.ws_item_sk = p.i_item_sk
    JOIN web_page_strings wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
),
union_all_sales AS (
    SELECT d_date, channel, quantity, net_paid, prod_name_snake, combined_desc_len, special_char_cnt, snake_word_cnt, double_len FROM catalog_sales_strings
    UNION ALL
    SELECT d_date, channel, quantity, net_paid, prod_name_snake, combined_desc_len, special_char_cnt, snake_word_cnt, double_len FROM store_sales_strings
    UNION ALL
    SELECT d_date, channel, quantity, net_paid, prod_name_snake, combined_desc_len, special_char_cnt, snake_word_cnt, double_len FROM web_sales_strings
),
aggregated_metrics AS (
    SELECT
        d_date,
        channel,
        count(*) AS sales_cnt,
        sum(quantity) AS total_quantity,
        sum(net_paid) AS total_net_paid,
        avg(combined_desc_len) AS avg_combined_desc_len,
        approx_distinct(prod_name_snake) AS distinct_product_snake,
        max(combined_desc_len) AS max_combined_desc_len,
        sum(special_char_cnt) AS total_special_char_cnt,
        sum(snake_word_cnt) AS total_snake_word_cnt,
        sum(double_len) AS total_double_len
    FROM union_all_sales
    GROUP BY d_date, channel
)
SELECT *
FROM aggregated_metrics
ORDER BY d_date, channel
