WITH cust_info AS (
  SELECT
    c.c_customer_sk,
    lower(trim(concat_ws(' ', c.c_first_name, c.c_last_name))) AS cust_norm_name,
    reverse(lower(trim(concat_ws(' ', c.c_first_name, c.c_last_name)))) AS cust_rev_name,
    length(regexp_replace(lower(trim(concat_ws(' ', c.c_first_name, c.c_last_name))), '[^aeiou]', '')) AS cust_vowel_cnt,
    ca.ca_state,
    ca.ca_city
  FROM customer c
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_info AS (
  SELECT
    i.i_item_sk,
    lower(trim(i.i_product_name)) AS item_norm_name,
    length(i.i_product_name) AS item_name_len,
    length(regexp_replace(lower(i.i_product_name), '[^aeiou]', '')) AS item_vowel_cnt,
    i.i_category,
    i.i_class,
    i.i_brand
  FROM item i
),
call_center_info AS (
  SELECT
    cc.cc_call_center_sk,
    lower(trim(cc.cc_name)) AS cc_norm_name,
    length(cc.cc_name) AS cc_name_len,
    replace(cc.cc_manager, '-', ' ') AS cc_manager_clean,
    regexp_replace(cc.cc_hours, '\\s+', ' ') AS cc_hours_norm
  FROM call_center cc
),
catalog_page_info AS (
  SELECT
    cp.cp_catalog_page_sk,
    lower(trim(cp.cp_description)) AS cp_desc_norm,
    length(cp.cp_description) AS cp_desc_len,
    length(regexp_replace(cp.cp_description, '[^aeiou]', '')) AS cp_desc_vowel_cnt,
    replace(cp.cp_type, '_', ' ') AS cp_type_clean,
    split(cp.cp_description, ' ')[1] AS cp_first_word,
    upper(cp.cp_description) AS cp_desc_upper
  FROM catalog_page cp
),
web_page_info AS (
  SELECT
    wp.wp_web_page_sk,
    lower(trim(wp.wp_url)) AS wp_url_norm,
    regexp_replace(wp.wp_url, '^https?://', '') AS wp_url_no_proto,
    split(wp.wp_url, '/')[3] AS wp_domain,
    lower(split(wp.wp_url, '/')[3]) AS wp_domain_lc,
    length(split(wp.wp_url, '/')[3]) AS wp_domain_len,
    reverse(split(wp.wp_url, '/')[3]) AS wp_domain_rev,
    concat_ws('-', wp.wp_type, CAST(wp.wp_char_count AS VARCHAR)) AS wp_type_char_concat,
    replace(wp.wp_url, '-', '_') AS wp_url_hyphens_to_underscores
  FROM web_page wp
),
cat_sales AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_net_profit,
    cs.cs_quantity,
    cust.cust_norm_name,
    cust.cust_rev_name,
    cust.cust_vowel_cnt,
    cust.ca_state,
    cust.ca_city,
    item.item_norm_name,
    item.item_name_len,
    item.item_vowel_cnt,
    item.i_category,
    item.i_class,
    item.i_brand,
    cc.cc_norm_name,
    cc.cc_name_len,
    cc.cc_manager_clean,
    cc.cc_hours_norm,
    cp.cp_desc_norm,
    cp.cp_desc_len,
    cp.cp_desc_vowel_cnt,
    cp.cp_type_clean,
    cp.cp_first_word,
    cp.cp_desc_upper,
    'catalog' AS source
  FROM catalog_sales cs
  JOIN cust_info cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
  JOIN item_info item ON cs.cs_item_sk = item.i_item_sk
  JOIN call_center_info cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page_info cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
),
web_sales AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_web_page_sk,
    ws.ws_net_profit,
    ws.ws_quantity,
    cust.cust_norm_name,
    cust.cust_rev_name,
    cust.cust_vowel_cnt,
    cust.ca_state,
    cust.ca_city,
    item.item_norm_name,
    item.item_name_len,
    item.item_vowel_cnt,
    item.i_category,
    item.i_class,
    item.i_brand,
    wp.wp_url_norm,
    wp.wp_url_no_proto,
    wp.wp_domain,
    wp.wp_domain_lc,
    wp.wp_domain_len,
    wp.wp_domain_rev,
    wp.wp_type_char_concat,
    wp.wp_url_hyphens_to_underscores,
    'web' AS source
  FROM web_sales ws
  JOIN cust_info cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
  JOIN item_info item ON ws.ws_item_sk = item.i_item_sk
  JOIN web_page_info wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
unified_sales AS (
  SELECT
    ca_state,
    i_category,
    cs_net_profit AS net_profit,
    cs_quantity AS quantity,
    item_name_len,
    item_vowel_cnt,
    cc_norm_name,
    cc_name_len,
    cp_desc_len,
    NULL AS wp_domain,
    NULL AS wp_domain_len,
    source
  FROM cat_sales
  UNION ALL
  SELECT
    ca_state,
    i_category,
    ws_net_profit AS net_profit,
    ws_quantity AS quantity,
    item_name_len,
    item_vowel_cnt,
    NULL AS cc_norm_name,
    NULL AS cc_name_len,
    NULL AS cp_desc_len,
    wp_domain,
    wp_domain_len,
    source
  FROM web_sales
)
SELECT
  ca_state,
  i_category,
  count(*) AS txn_count,
  sum(net_profit) AS total_profit,
  avg(item_name_len) AS avg_item_name_len,
  avg(item_vowel_cnt) AS avg_item_vowel_cnt,
  min(cc_name_len) AS min_cc_name_len,
  max(cc_name_len) AS max_cc_name_len,
  avg(wp_domain_len) AS avg_wp_domain_len,
  array_join(array_agg(DISTINCT substring(cc_norm_name, 1, 5)) FILTER (WHERE cc_norm_name IS NOT NULL), ',') AS cc_name_prefixes,
  array_join(array_agg(DISTINCT lower(wp_domain)) FILTER (WHERE wp_domain IS NOT NULL), ',') AS wp_domains
FROM unified_sales
GROUP BY ca_state, i_category
