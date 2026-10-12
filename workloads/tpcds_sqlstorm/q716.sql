WITH item_str AS (
    SELECT
        i.i_item_sk,
        lower(i.i_product_name) AS i_name_lower,
        upper(i.i_product_name) AS i_name_upper,
        substr(i.i_product_name, 1, 5) AS i_name_prefix,
        length(i.i_product_name) AS i_name_len,
        replace(i.i_product_name, '-', '') AS i_name_no_dash,
        regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '') AS i_name_alphanum,
        cardinality(split(i.i_item_desc, ' ')) AS i_desc_word_cnt,
        regexp_like(i.i_item_desc, '\\d') AS i_desc_has_digit,
        CASE WHEN regexp_like(i.i_product_name, '^[AEIOU]') THEN 'V' ELSE 'C' END AS i_initial_type
    FROM item i
),
cust_str AS (
    SELECT
        c.c_customer_sk,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS c_full_name,
        lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS c_full_name_lower,
        regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS c_email_local,
        length(c.c_email_address) AS c_email_len,
        replace(c.c_email_address, '@', '_at_') AS c_email_sanitized,
        trim(both ' ' FROM c.c_salutation) AS c_salutation_trim
    FROM customer c
),
webpage_str AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS wp_domain,
        length(wp.wp_url) AS wp_url_len,
        regexp_replace(wp.wp_url, '[^a-zA-Z0-9]', '') AS wp_url_alphanum,
        substr(wp.wp_url, strpos(wp.wp_url, ':') + 3, 20) AS wp_url_prefix,
        cardinality(split(wp.wp_url, '/')) AS wp_url_path_segments,
        CASE WHEN regexp_like(wp.wp_url, '\\.com') THEN 'COM' ELSE 'OTHER' END AS wp_domain_type
    FROM web_page wp
),
promo_str AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        lower(p.p_promo_name) AS p_name_lower,
        length(p.p_promo_name) AS p_name_len,
        regexp_replace(p.p_promo_name, '\\s+', '_') AS p_name_underscore,
        cardinality(split(p.p_promo_name, ' ')) AS p_name_word_cnt,
        CASE WHEN regexp_like(p.p_promo_name, 'discount') THEN 'DISCOUNT' ELSE 'OTHER' END AS p_type_flag
    FROM promotion p
),
callcenter_str AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_manager,
        concat_ws(' - ', cc.cc_name, cc.cc_manager) AS cc_name_manager,
        upper(cc.cc_name) AS cc_name_upper,
        lower(cc.cc_manager) AS cc_manager_lower,
        length(cc.cc_name) AS cc_name_len,
        length(cc.cc_manager) AS cc_manager_len,
        regexp_replace(cc.cc_name, '\\s+', ' ') AS cc_name_normalized
    FROM call_center cc
),
sales_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
)
SELECT
    i.i_name_lower,
    i.i_name_upper,
    i.i_name_prefix,
    i.i_name_len,
    i.i_desc_word_cnt,
    i.i_initial_type,
    c.c_full_name,
    c.c_full_name_lower,
    c.c_email_local,
    c.c_email_len,
    wp.wp_domain,
    wp.wp_url_len,
    wp.wp_url_alphanum,
    wp.wp_domain_type,
    p.p_type_flag,
    cc.cc_name_manager,
    cc.cc_name_upper,
    cc.cc_manager_lower,
    COUNT(*) AS txn_cnt,
    SUM(s.ws_net_paid) AS total_net_paid,
    AVG(s.ws_quantity) AS avg_qty,
    SUM(length(i.i_name_lower) + i.i_name_len + i.i_desc_word_cnt + c.c_email_len + wp.wp_url_len) AS total_string_metric
FROM sales_base s
JOIN item_str i ON s.ws_item_sk = i.i_item_sk
JOIN cust_str c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN webpage_str wp ON s.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN promo_str p ON s.ws_promo_sk = p.p_promo_sk
CROSS JOIN callcenter_str cc
GROUP BY
    i.i_name_lower,
    i.i_name_upper,
    i.i_name_prefix,
    i.i_name_len,
    i.i_desc_word_cnt,
    i.i_initial_type,
    c.c_full_name,
    c.c_full_name_lower,
    c.c_email_local,
    c.c_email_len,
    wp.wp_domain,
    wp.wp_url_len,
    wp.wp_url_alphanum,
    wp.wp_domain_type,
    p.p_type_flag,
    cc.cc_name_manager,
    cc.cc_name_upper,
    cc.cc_manager_lower
ORDER BY total_net_paid DESC
LIMIT 100
