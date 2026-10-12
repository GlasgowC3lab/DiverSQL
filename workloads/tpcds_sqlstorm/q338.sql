WITH sales_str AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    element_at(split(c.c_email_address, '@'), 2) AS email_domain,
    element_at(split(c.c_email_address, '@'), 1) AS email_local,
    cs.cs_net_paid,
    i.i_product_name,
    i.i_item_desc,
    p.p_promo_name,
    cc.cc_manager,
    cp.cp_description,
    length(i.i_product_name) AS product_name_len,
    cardinality(split(i.i_product_name, ' ')) AS product_name_word_cnt,
    length(regexp_replace(i.i_item_desc, '[^A-Za-z0-9 ]', '')) AS cleaned_desc_len,
    CAST(regexp_extract(i.i_item_desc, '(\\d+)', 1) AS integer) AS first_number_in_desc,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)discount') THEN 1 ELSE 0 END AS is_discount_promo,
    CASE WHEN regexp_like(cc.cc_manager, '(?i)smith') THEN 1 ELSE 0 END AS is_smith_manager,
    length(replace(element_at(split(c.c_email_address, '@'), 1), '.', '')) AS email_local_len_no_dots,
    length(cp.cp_description) AS page_desc_len,
    cardinality(split(cp.cp_description, ' ')) AS page_desc_word_cnt,
    lower(i.i_product_name) AS product_name_lcase,
    upper(i.i_product_name) AS product_name_ucase,
    concat_ws(' - ', i.i_product_name, i.i_item_desc) AS concat_product_desc,
    concat('promo-', p.p_promo_id) AS promo_key,
    substr(i.i_product_name, 1, 5) AS product_name_prefix,
    position(' ' IN i.i_product_name) AS first_space_position,
    reverse(i.i_product_name) AS product_name_rev,
    translate(i.i_product_name, 'aeiou', 'AEIOU') AS product_name_vowel_upper,
    regexp_replace(i.i_product_name, '[aeiou]', '*') AS product_name_vowel_mask
  FROM
    catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE
    d.d_year = 2001
    AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
)
SELECT
  d_year,
  d_month_seq,
  email_domain,
  COUNT(DISTINCT email_local) AS distinct_local_parts,
  SUM(cs_net_paid) AS total_net_paid,
  AVG(product_name_len) AS avg_product_name_len,
  AVG(product_name_word_cnt) AS avg_product_name_word_cnt,
  AVG(cleaned_desc_len) AS avg_clean_desc_len,
  MIN(first_number_in_desc) AS min_number_in_desc,
  MAX(first_number_in_desc) AS max_number_in_desc,
  SUM(is_discount_promo) AS discount_promo_cnt,
  SUM(is_smith_manager) AS smith_manager_cnt,
  AVG(email_local_len_no_dots) AS avg_email_local_len_no_dots,
  AVG(page_desc_len) AS avg_page_desc_len,
  AVG(page_desc_word_cnt) AS avg_page_desc_word_cnt,
  COUNT(*) AS total_rows,
  MIN(length(product_name_lcase)) AS min_lcase_len,
  MAX(length(product_name_ucase)) AS max_ucase_len,
  COUNT(DISTINCT concat_product_desc) AS distinct_concat_product_desc,
  COUNT(DISTINCT promo_key) AS distinct_promo_key,
  COUNT(DISTINCT product_name_prefix) AS distinct_product_name_prefix,
  MIN(first_space_position) AS min_first_space_position,
  AVG(length(product_name_rev)) AS avg_rev_len,
  COUNT(DISTINCT product_name_vowel_mask) AS distinct_vowel_mask
FROM
  sales_str
GROUP BY
  d_year,
  d_month_seq,
  email_domain
ORDER BY
  d_year,
  d_month_seq,
  email_domain
