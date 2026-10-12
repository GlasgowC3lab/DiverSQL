WITH store_info AS (
  SELECT
    s.s_store_sk,
    s.s_store_id,
    s.s_store_name,
    concat_ws(' - ', s.s_store_name, s.s_city, s.s_state) AS full_store_desc,
    lower(s.s_store_name) AS store_name_lower,
    upper(s.s_store_name) AS store_name_upper,
    reverse(s.s_store_name) AS store_name_rev,
    length(s.s_store_name) AS store_name_len,
    cardinality(split(s.s_store_name, ' ')) AS store_name_word_cnt,
    regexp_replace(s.s_store_name, '[^A-Za-z]', '') AS store_name_alpha,
    concat(substr(s.s_store_name, 1, 3), substr(s.s_store_name, length(s.s_store_name) - 2, 3)) AS store_name_head_tail,
    s.s_city,
    s.s_state,
    s.s_country
  FROM store s
),
item_info AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    lower(i.i_item_desc) AS item_desc_lower,
    regexp_replace(i.i_item_desc, '[^a-zA-Z0-9]', ' ') AS item_desc_cleaned,
    split(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9]', ' '), ' ') AS item_desc_words,
    cardinality(split(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9]', ' '), ' ')) AS item_desc_word_cnt,
    length(i.i_item_desc) AS item_desc_len,
    substr(i.i_product_name, 1, 5) AS product_name_prefix,
    concat(i.i_product_name, '_', i.i_brand) AS full_product_name
  FROM item i
),
promo_info AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    upper(p.p_promo_name) AS promo_name_upper,
    lower(p.p_promo_name) AS promo_name_lower,
    regexp_replace(p.p_promo_name, '[^a-zA-Z0-9]', '') AS promo_name_alphanum,
    reverse(p.p_promo_name) AS promo_name_rev,
    cardinality(split(p.p_promo_name, ' ')) AS promo_name_word_cnt,
    p.p_channel_email,
    p.p_channel_tv,
    p.p_channel_radio,
    p.p_promo_id
  FROM promotion p
),
call_center_info AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_call_center_id,
    cc.cc_name,
    lower(cc.cc_name) AS cc_name_lower,
    upper(cc.cc_name) AS cc_name_upper,
    reverse(cc.cc_name) AS cc_name_rev,
    length(cc.cc_name) AS cc_name_len,
    cardinality(split(cc.cc_name, ' ')) AS cc_name_word_cnt,
    regexp_replace(cc.cc_name, '[^A-Za-z]', '') AS cc_name_alpha,
    concat(substr(cc.cc_name, 1, 3), substr(cc.cc_name, length(cc.cc_name) - 2, 3)) AS cc_name_head_tail,
    cc.cc_hours,
    cc.cc_manager,
    regexp_replace(cc.cc_hours, '[^0-9:-]', '') AS cc_hours_clean,
    regexp_replace(cc.cc_manager, '[^A-Za-z ]', '') AS cc_manager_alpha
  FROM call_center cc
),
web_info AS (
  SELECT
    wp.wp_web_page_sk,
    wp.wp_url,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS url_domain,
    lower(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)) AS url_domain_lower,
    replace(wp.wp_url, 'http://', '') AS url_no_http,
    replace(wp.wp_url, 'https://', '') AS url_no_https,
    split(wp.wp_url, '/') AS url_parts,
    cardinality(split(wp.wp_url, '/')) AS url_part_cnt,
    length(wp.wp_url) AS url_len,
    substr(wp.wp_url, 1, 30) AS url_prefix,
    regexp_replace(wp.wp_url, '[^a-zA-Z]', '') AS url_alpha
  FROM web_page wp
),
store_sales_agg AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_promo_sk AS promo_sk,
    sum(ss.ss_net_paid) AS total_sales,
    sum(ss.ss_quantity) AS total_qty,
    avg(ss.ss_net_paid) AS avg_sale,
    count(*) AS txn_cnt,
    max(ss.ss_sold_date_sk) AS max_date_sk,
    min(ss.ss_sold_date_sk) AS min_date_sk
  FROM store_sales ss
  GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_promo_sk
),
catalog_sales_agg AS (
  SELECT
    cs.cs_call_center_sk AS call_center_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_promo_sk AS promo_sk,
    sum(cs.cs_net_paid) AS total_sales,
    sum(cs.cs_quantity) AS total_qty,
    avg(cs.cs_net_paid) AS avg_sale,
    count(*) AS txn_cnt,
    max(cs.cs_sold_date_sk) AS max_date_sk,
    min(cs.cs_sold_date_sk) AS min_date_sk
  FROM catalog_sales cs
  GROUP BY cs.cs_call_center_sk, cs.cs_item_sk, cs.cs_promo_sk
)
SELECT *
FROM (
  SELECT
    'store' AS channel,
    concat_ws('_', si.s_store_id, ii.i_item_id, pi.p_promo_id) AS composite_key,
    si.s_store_name AS primary_name,
    si.store_name_lower,
    si.store_name_rev,
    si.store_name_word_cnt,
    ii.full_product_name,
    ii.item_desc_cleaned,
    ii.item_desc_word_cnt,
    pi.promo_name_upper,
    pi.promo_name_rev,
    pi.promo_name_word_cnt,
    wi.sample_url,
    wi.sample_domain,
    concat_ws(' ', si.store_name_lower, ii.item_desc_lower, pi.promo_name_lower) AS combined_lower_text,
    length(concat_ws(' ', si.store_name_lower, ii.item_desc_lower, pi.promo_name_lower)) AS combined_text_len,
    cardinality(split(concat_ws(' ', si.store_name_lower, ii.item_desc_lower, pi.promo_name_lower), ' ')) AS combined_word_cnt,
    sa.total_sales,
    sa.total_qty,
    round(sa.avg_sale, 2) AS avg_sale,
    sa.txn_cnt,
    d.d_year,
    d.d_month_seq
  FROM store_sales_agg sa
  JOIN store_info si ON sa.store_sk = si.s_store_sk
  JOIN item_info ii ON sa.item_sk = ii.i_item_sk
  JOIN promo_info pi ON sa.promo_sk = pi.p_promo_sk
  JOIN date_dim d ON sa.max_date_sk = d.d_date_sk
  CROSS JOIN (SELECT wp_url AS sample_url, url_domain AS sample_domain FROM web_info LIMIT 1) wi
  WHERE d.d_year BETWEEN 2000 AND 2002

  UNION ALL

  SELECT
    'catalog' AS channel,
    concat_ws('_', cc.cc_call_center_id, ii.i_item_id, pi.p_promo_id) AS composite_key,
    cc.cc_name AS primary_name,
    cc.cc_name_lower,
    cc.cc_name_rev,
    cc.cc_name_word_cnt,
    ii.full_product_name,
    ii.item_desc_cleaned,
    ii.item_desc_word_cnt,
    pi.promo_name_upper,
    pi.promo_name_rev,
    pi.promo_name_word_cnt,
    wi.sample_url,
    wi.sample_domain,
    concat_ws(' ', cc.cc_name_lower, ii.item_desc_lower, pi.promo_name_lower) AS combined_lower_text,
    length(concat_ws(' ', cc.cc_name_lower, ii.item_desc_lower, pi.promo_name_lower)) AS combined_text_len,
    cardinality(split(concat_ws(' ', cc.cc_name_lower, ii.item_desc_lower, pi.promo_name_lower), ' ')) AS combined_word_cnt,
    ca.total_sales,
    ca.total_qty,
    round(ca.avg_sale, 2) AS avg_sale,
    ca.txn_cnt,
    d.d_year,
    d.d_month_seq
  FROM catalog_sales_agg ca
  JOIN call_center_info cc ON ca.call_center_sk = cc.cc_call_center_sk
  JOIN item_info ii ON ca.item_sk = ii.i_item_sk
  JOIN promo_info pi ON ca.promo_sk = pi.p_promo_sk
  JOIN date_dim d ON ca.max_date_sk = d.d_date_sk
  CROSS JOIN (SELECT wp_url AS sample_url, url_domain AS sample_domain FROM web_info LIMIT 1) wi
  WHERE d.d_year BETWEEN 2000 AND 2002
) t
ORDER BY t.total_sales DESC
LIMIT 200
