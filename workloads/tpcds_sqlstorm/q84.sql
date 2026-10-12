WITH
customer_strings AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat(substr(c.c_first_name, 1, 1), substr(c.c_last_name, 1, 1)) AS initials,
        lower(regexp_replace(c.c_email_address, '\\s+', '')) AS email_clean,
        lower(element_at(split(c.c_email_address, '@'), 2)) AS email_domain,
        replace(c.c_last_name, ' ', '_') AS last_name_underscore,
        length(c.c_email_address) AS email_length
    FROM customer c
),
item_strings AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        lower(i.i_product_name) AS product_name_lower,
        regexp_replace(i.i_product_name, '[AEIOUaeiou]', '') AS product_name_no_vowels,
        regexp_replace(i.i_product_name, '[^[:alnum:]]', '') AS product_name_alnum,
        substr(i.i_product_name, 1, 5) AS product_prefix,
        length(i.i_product_name) AS product_name_len,
        reverse(i.i_product_name) AS product_name_reverse
    FROM item i
),
web_page_strings AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        regexp_extract(wp.wp_url, '://([^/]+)', 1) AS url_domain_raw,
        lower(regexp_extract(wp.wp_url, '://([^/]+)', 1)) AS url_domain_lower,
        replace(wp.wp_url, 'http://', 'https://') AS url_https,
        regexp_replace(wp.wp_url, '[^[:alnum:].]', '') AS url_alnum,
        length(wp.wp_url) AS url_length,
        substr(wp.wp_url, 1, 10) AS url_prefix
    FROM web_page wp
),
catalog_page_strings AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_description,
        lower(cp.cp_description) AS description_lower,
        replace(cp.cp_description, '\n', ' ') AS description_clean,
        regexp_replace(cp.cp_description, '[^[:alnum:] ]', '') AS description_alnum,
        length(cp.cp_description) AS description_len,
        substr(cp.cp_description, 1, 10) AS description_prefix
    FROM catalog_page cp
),
call_center_strings AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        lower(cc.cc_name) AS cc_name_lower,
        replace(cc.cc_name, ' ', '_') AS cc_name_underscore,
        length(cc.cc_name) AS cc_name_len,
        substr(cc.cc_name, 1, 3) AS cc_name_prefix
    FROM call_center cc
)
SELECT
    s.s_store_id,
    s.s_store_name,
    concat_ws(' ', s.s_store_name, cc_strings.cc_name_underscore, wp_strings.url_domain_lower) AS combined_key,
    lower(concat_ws('_', cust_strings.initials, item_str.product_name_no_vowels, cp_strings.description_prefix)) AS hashable_string,
    sum(coalesce(ss.ss_net_paid, 0)) AS total_store_sales,
    sum(coalesce(cs.cs_net_paid, 0)) AS total_catalog_sales,
    sum(coalesce(ws.ws_net_paid, 0)) AS total_web_sales,
    count(distinct i.i_item_sk) AS distinct_items_sold,
    approx_distinct(cust_strings.email_domain) AS approx_email_domains,
    max(length(cp_strings.description_alnum)) AS max_desc_alnum_len,
    min(item_str.product_name_len) AS min_product_name_len,
    max(wp_strings.url_length) AS max_url_length,
    count(*) AS rows_processed
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN item_strings item_str ON i.i_item_sk = item_str.i_item_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_strings cust_strings ON c.c_customer_sk = cust_strings.c_customer_sk
LEFT JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN call_center_strings cc_strings ON cc.cc_call_center_sk = cc_strings.cc_call_center_sk
LEFT JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_page_strings wp_strings ON wp.wp_web_page_sk = wp_strings.wp_web_page_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_page_strings cp_strings ON cp.cp_catalog_page_sk = cp_strings.cp_catalog_page_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    cc_strings.cc_name_underscore,
    wp_strings.url_domain_lower,
    cust_strings.initials,
    item_str.product_name_no_vowels,
    cp_strings.description_prefix
ORDER BY total_store_sales DESC
LIMIT 50
