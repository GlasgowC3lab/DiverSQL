WITH
customer_str AS (
 SELECT
   c_customer_sk,
   lower(c_first_name) AS first_name_l,
   lower(c_last_name) AS last_name_l,
   concat_ws(' ', c_first_name, c_last_name) AS full_name,
   split(concat_ws(' ', c_first_name, c_last_name), ' ') AS full_name_words,
   array_join(split(concat_ws(' ', c_first_name, c_last_name), ' '), '-') AS hyphenated_name,
   length(regexp_replace(concat_ws(' ', c_first_name, c_last_name), '\\s+', '')) AS name_nospace_len,
   c_email_address,
   regexp_replace(c_email_address, '[^a-zA-Z0-9@.]', '') AS cleaned_email,
   length(regexp_replace(c_email_address, '[^a-zA-Z0-9@.]', '')) AS email_clean_len,
   cardinality(split(c_email_address, '@')) AS email_at_parts
 FROM customer
),
item_str AS (
 SELECT
   i_item_sk,
   i_product_name,
   upper(i_product_name) AS upper_name,
   regexp_replace(i_product_name, '[^a-zA-Z0-9 ]', '') AS cleaned_name,
   length(i_product_name) AS product_name_len,
   split(i_product_name, ' ') AS product_name_words,
   cardinality(split(i_product_name, ' ')) AS product_word_count,
   length(regexp_replace(i_product_name, '[aeiouAEIOU]', '')) AS consonant_len
 FROM item
),
store_sales_str AS (
 SELECT
   ss.ss_sold_date_sk AS sold_date_sk,
   ss.ss_quantity AS quantity,
   ss.ss_net_paid AS net_paid,
   'store' AS sales_channel,
   cs.full_name AS cust_full_name,
   cs.cleaned_email AS cust_clean_email,
   i.upper_name AS item_up_name,
   s.s_store_name AS extra_str,
   concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, s.s_store_name) AS composite_str,
   length(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, s.s_store_name)) AS comp_str_len,
   regexp_like(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, s.s_store_name), '^[A-Z]') AS starts_with_upper,
   regexp_replace(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, s.s_store_name), '[^A-Z0-9|]', '') AS alnum_str,
   reverse(cs.full_name) AS reversed_full_name,
   substr(cs.full_name, 1, 10) AS first_10_chars,
   length(regexp_replace(cs.full_name, '\\s', '')) AS nospace_len,
   concat_ws('-', cs.hyphenated_name, i.upper_name) AS combined_hyphen_str,
   CAST(NULL AS integer) AS desc_word_cnt,
   CAST(NULL AS integer) AS url_part_cnt
 FROM store_sales ss
 JOIN customer_str cs ON ss.ss_customer_sk = cs.c_customer_sk
 JOIN item_str i ON ss.ss_item_sk = i.i_item_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
),
web_sales_str AS (
 SELECT
   ws.ws_sold_date_sk AS sold_date_sk,
   ws.ws_quantity AS quantity,
   ws.ws_net_paid AS net_paid,
   'web' AS sales_channel,
   cs.full_name AS cust_full_name,
   cs.cleaned_email AS cust_clean_email,
   i.upper_name AS item_up_name,
   wp.wp_url AS extra_str,
   concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, wp.wp_url) AS composite_str,
   length(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, wp.wp_url)) AS comp_str_len,
   regexp_like(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, wp.wp_url), '^[A-Z]') AS starts_with_upper,
   regexp_replace(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, wp.wp_url), '[^A-Z0-9|]', '') AS alnum_str,
   reverse(cs.full_name) AS reversed_full_name,
   substr(cs.full_name, 1, 10) AS first_10_chars,
   length(regexp_replace(cs.full_name, '\\s', '')) AS nospace_len,
   concat_ws('-', cs.hyphenated_name, i.upper_name) AS combined_hyphen_str,
   CAST(NULL AS integer) AS desc_word_cnt,
   cardinality(split(wp.wp_url, '/')) AS url_part_cnt
 FROM web_sales ws
 JOIN customer_str cs ON ws.ws_bill_customer_sk = cs.c_customer_sk
 JOIN item_str i ON ws.ws_item_sk = i.i_item_sk
 JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
catalog_sales_str AS (
 SELECT
   csa.cs_sold_date_sk AS sold_date_sk,
   csa.cs_quantity AS quantity,
   csa.cs_net_paid AS net_paid,
   'catalog' AS sales_channel,
   cs.full_name AS cust_full_name,
   cs.cleaned_email AS cust_clean_email,
   i.upper_name AS item_up_name,
   cp.cp_type AS extra_str,
   concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, cp.cp_type) AS composite_str,
   length(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, cp.cp_type)) AS comp_str_len,
   regexp_like(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, cp.cp_type), '^[A-Z]') AS starts_with_upper,
   regexp_replace(concat_ws('|', cs.full_name, cs.cleaned_email, i.upper_name, cp.cp_type), '[^A-Z0-9|]', '') AS alnum_str,
   reverse(cs.full_name) AS reversed_full_name,
   substr(cs.full_name, 1, 10) AS first_10_chars,
   length(regexp_replace(cs.full_name, '\\s', '')) AS nospace_len,
   concat_ws('-', cs.hyphenated_name, i.upper_name) AS combined_hyphen_str,
   cardinality(split(cp.cp_description, ' ')) AS desc_word_cnt,
   CAST(NULL AS integer) AS url_part_cnt
 FROM catalog_sales csa
 JOIN customer_str cs ON csa.cs_bill_customer_sk = cs.c_customer_sk
 JOIN item_str i ON csa.cs_item_sk = i.i_item_sk
 JOIN catalog_page cp ON csa.cs_catalog_page_sk = cp.cp_catalog_page_sk
),
combined_sales_str AS (
 SELECT * FROM store_sales_str
 UNION ALL
 SELECT * FROM web_sales_str
 UNION ALL
 SELECT * FROM catalog_sales_str
)
SELECT
 d.d_year,
 s.sales_channel,
 COUNT(*) AS sales_cnt,
 SUM(s.quantity) AS total_qty,
 SUM(s.net_paid) AS total_net_paid,
 AVG(s.comp_str_len) AS avg_comp_len,
 SUM(CASE WHEN s.starts_with_upper THEN 1 ELSE 0 END) AS starts_with_upper_cnt,
 AVG(LENGTH(s.alnum_str)) AS avg_alnum_len,
 SUM(LENGTH(regexp_replace(s.composite_str, '[AEIOUaeiou]', ''))) AS total_consonants,
 AVG(s.nospace_len) AS avg_name_nospace_len,
 COUNT(DISTINCT s.reversed_full_name) AS distinct_rev_name_cnt,
 AVG(LENGTH(s.combined_hyphen_str)) AS avg_combined_hyphen_len,
 SUM(s.desc_word_cnt) AS total_desc_word_cnt,
 AVG(s.url_part_cnt) AS avg_url_part_cnt
FROM combined_sales_str s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
GROUP BY d.d_year, s.sales_channel
ORDER BY d.d_year, s.sales_channel
