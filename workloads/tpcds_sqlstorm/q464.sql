WITH
item_strings AS (
 SELECT
   i_item_sk,
   i_item_id,
   lower(i_product_name) AS lower_product_name,
   upper(i_color) AS color_upper,
   regexp_replace(i_item_desc, '[^A-Za-z0-9]', '') AS cleaned_desc,
   regexp_extract(i_item_desc, '(\\d+)', 1) AS first_number_in_desc,
   length(i_product_name) AS len_product_name,
   cardinality(split(i_item_desc, ' ')) AS desc_word_count,
   substr(i_item_desc, 1, 20) AS desc_prefix,
   replace(i_product_name, ' ', '-') AS product_name_dash,
   concat_ws('_', i_brand, i_class, i_category) AS brand_hierarchy,
   format('%s-%s', i_item_id, i_item_desc) AS formatted_item
 FROM item
),
customer_strings AS (
 SELECT
   c_customer_sk,
   c_customer_id,
   lower(c_email_address) AS lower_email,
   lower(c_login) AS lower_login,
   element_at(split(c_email_address, '@'), 2) AS email_domain,
   lower(element_at(split(c_email_address, '@'), 2)) AS email_domain_lower,
   lower(c_first_name) AS lower_first_name,
   lower(c_last_name) AS lower_last_name,
   concat_ws(' ', c_first_name, c_last_name) AS full_name,
   length(c_first_name) AS len_first_name,
   length(c_last_name) AS len_last_name,
   regexp_replace(c_email_address, '[^A-Za-z0-9@.]', '') AS cleaned_email
 FROM customer
),
promotion_strings AS (
 SELECT
   p_promo_sk,
   lower(p_promo_name) AS lower_promo_name,
   regexp_replace(p_channel_details, '[\\r\\n]', ' ') AS cleaned_channel_details,
   CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END AS discount_active_flag,
   replace(p_promo_name, '&', 'and') AS promo_name_clean,
   length(p_promo_name) AS promo_name_len,
   cardinality(split(p_promo_name, ' ')) AS promo_word_count
 FROM promotion
)
SELECT
  s.s_store_name,
  d.d_year,
  ist.lower_product_name,
  count(*) AS total_sales_transactions,
  sum(ss.ss_ext_sales_price) AS total_sales_amount,
  avg(ist.len_product_name) AS avg_product_name_len,
  avg(ist.desc_word_count) AS avg_desc_word_count,
  count(DISTINCT ist.lower_product_name) AS distinct_product_names,
  count(DISTINCT cs.email_domain_lower) AS distinct_email_domains,
  sum(promo.promo_name_len) AS total_promo_name_len,
  avg(length(cc.cc_name)) AS avg_call_center_name_len,
  count(DISTINCT lower(cc.cc_manager)) AS distinct_call_center_managers,
  concat_ws('|', s.s_store_id, cc.cc_call_center_id, ist.lower_product_name) AS composite_key,
  format('%s-%s-%s', s.s_store_id, ist.i_item_id, cs.c_customer_id) AS unique_transaction_id,
  length(regexp_replace(cc.cc_hours, '[^0-9:-]', '')) AS cleaned_hours_len,
  cardinality(split(cc.cc_hours, '-')) AS cc_hours_segments,
  sum(CASE WHEN promo.discount_active_flag = 1 THEN ss.ss_ext_sales_price * 0.9 ELSE ss.ss_ext_sales_price END) AS adjusted_sales_amount
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item_strings ist ON ss.ss_item_sk = ist.i_item_sk
JOIN customer_strings cs ON ss.ss_customer_sk = cs.c_customer_sk
LEFT JOIN promotion_strings promo ON ss.ss_promo_sk = promo.p_promo_sk
JOIN call_center cc ON s.s_state = cc.cc_state
WHERE s.s_state = 'CA'
  AND d.d_year = 2001
GROUP BY
  s.s_store_name,
  d.d_year,
  s.s_store_id,
  cc.cc_call_center_id,
  ist.lower_product_name,
  ist.i_item_id,
  cs.c_customer_id,
  cc.cc_hours,
  promo.discount_active_flag
ORDER BY total_sales_amount DESC
LIMIT 100
