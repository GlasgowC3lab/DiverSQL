WITH item_str AS (
    SELECT
        i_item_sk,
        i_product_name,
        lower(i_product_name) AS prod_name_lc,
        upper(i_product_name) AS prod_name_uc,
        trim(i_product_name) AS prod_name_trim,
        regexp_replace(i_product_name, '\\s+', ' ') AS prod_name_norm,
        regexp_replace(i_product_name, '[^A-Za-z]', '') AS prod_name_alpha,
        length(i_product_name) AS prod_name_len,
        cardinality(split(i_product_name, '\\s+')) AS prod_word_cnt,
        substr(i_product_name, 1, 4) AS prod_prefix,
        reverse(i_product_name) AS prod_rev,
        CASE WHEN regexp_like(i_product_name, '\\d') THEN 1 ELSE 0 END AS has_digit,
        regexp_extract(i_product_name, '(\\w+)$', 1) AS last_word
    FROM item
),
customer_str AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        lower(c_email_address) AS email_lc,
        split(c_email_address, '@')[2] AS email_domain_full,
        split(split(c_email_address, '@')[2], '\\.')[2] AS email_tld,
        length(c_email_address) AS email_len,
        concat_ws(' ', c_first_name, c_last_name) AS full_name,
        lower(concat_ws(' ', c_first_name, c_last_name)) AS full_name_lc,
        regexp_replace(c_email_address, '[^a-zA-Z0-9@.]', '') AS email_clean,
        CASE WHEN regexp_like(c_email_address, '\\.com$') THEN 'COM' ELSE 'OTHER' END AS email_tld_type,
        strpos(c_email_address, '@') AS email_at_pos
    FROM customer
),
promotion_str AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        lower(p_promo_name) AS promo_name_lc,
        regexp_replace(p_promo_name, '\\s+', '_') AS promo_name_underscored,
        regexp_replace(p_promo_name, '[^A-Za-z]', '') AS promo_name_alpha,
        length(p_promo_name) AS promo_name_len,
        CASE WHEN regexp_like(p_promo_name, 'discount') THEN 1 ELSE 0 END AS has_discount_word,
        concat_ws('|', p_channel_dmail, p_channel_email, p_channel_catalog) AS promo_channels_concat,
        cardinality(filter(array[p_channel_dmail, p_channel_email, p_channel_catalog, p_channel_tv, p_channel_radio, p_channel_press, p_channel_event, p_channel_demo], x -> x IS NOT NULL)) AS promo_channels_cnt
    FROM promotion
),
web_page_str AS (
    SELECT
        wp_web_page_sk,
        wp_url,
        lower(wp_url) AS url_lc,
        regexp_replace(wp_url, '^https?://', '') AS url_no_proto,
        length(wp_url) AS url_len,
        cardinality(split(wp_url, '/')) AS url_token_cnt,
        split(wp_url, '/')[3] AS domain_part,
        regexp_extract(wp_url, '://([^/]+)', 1) AS domain_extracted,
        reverse(wp_url) AS url_rev,
        substr(wp_url, 1, 10) AS url_prefix
    FROM web_page
),
warehouse_str AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        lower(w_warehouse_name) AS warehouse_name_lc,
        length(w_warehouse_name) AS warehouse_name_len,
        regexp_replace(w_warehouse_name, '\\s+', '_') AS warehouse_name_us
    FROM warehouse
),
ship_mode_str AS (
    SELECT
        sm_ship_mode_sk,
        sm_ship_mode_id,
        sm_type,
        sm_carrier,
        concat_ws('-', sm_ship_mode_id, sm_type) AS ship_mode_combined,
        lower(concat_ws('-', sm_ship_mode_id, sm_type)) AS ship_mode_combined_lc,
        length(sm_type) AS ship_type_len
    FROM ship_mode
),
web_sales_str AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ws_web_page_sk,
        ws_promo_sk,
        ws_warehouse_sk,
        ws_ship_mode_sk,
        ws_sold_date_sk,
        ws_sold_time_sk
    FROM web_sales
    WHERE ws_order_number IS NOT NULL
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_paid,
    i.prod_name_lc,
    i.prod_name_uc,
    i.prod_name_trim,
    i.prod_name_norm,
    i.prod_name_alpha,
    i.prod_name_len,
    i.prod_word_cnt,
    i.prod_prefix,
    i.prod_rev,
    i.has_digit,
    i.last_word,
    c.email_lc,
    c.email_domain_full,
    c.email_tld,
    c.email_len,
    c.full_name,
    c.full_name_lc,
    c.email_clean,
    c.email_tld_type,
    c.email_at_pos,
    p.promo_name_lc,
    p.promo_name_underscored,
    p.promo_name_alpha,
    p.promo_name_len,
    p.has_discount_word,
    p.promo_channels_concat,
    p.promo_channels_cnt,
    wp.url_lc,
    wp.url_no_proto,
    wp.url_len,
    wp.url_token_cnt,
    wp.domain_part,
    wp.domain_extracted,
    wp.url_rev,
    wp.url_prefix,
    w.warehouse_name_lc,
    w.warehouse_name_len,
    w.warehouse_name_us,
    sm.ship_mode_combined,
    sm.ship_mode_combined_lc,
    sm.ship_type_len,
    concat_ws('#', i.prod_prefix, c.email_tld, p.promo_name_underscored) AS composite_key,
    length(concat_ws('#', i.prod_prefix, c.email_tld, p.promo_name_underscored)) AS composite_key_len,
    regexp_replace(concat(i.prod_name_alpha, p.promo_name_alpha), '[^A-Za-z]', '') AS combined_alpha,
    cardinality(split(concat(i.prod_name_lc, ' ', c.full_name_lc, ' ', p.promo_name_lc), '\\s+')) AS total_word_count
FROM web_sales_str ws
JOIN item_str i ON ws.ws_item_sk = i.i_item_sk
JOIN customer_str c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN promotion_str p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page_str wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse_str w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode_str sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY ws.ws_order_number
LIMIT 100
