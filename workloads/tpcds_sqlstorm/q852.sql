SELECT
  c.cc_call_center_id,
  lower(c.cc_name) AS lc_name,
  replace(lower(c.cc_name), ' ', '_') AS lc_name_underscored,
  reverse(c.cc_manager) AS manager_rev,
  substr(c.cc_manager, 1, 5) AS manager_prefix,
  length(c.cc_hours) AS hours_len,
  CASE WHEN regexp_like(c.cc_hours, '[0-9]{2}:[0-9]{2}') THEN 'HAS_TIME' ELSE 'NO_TIME' END AS hours_time_flag,
  concat_ws(', ', c.cc_city, c.cc_state, c.cc_country) AS location,
  concat_ws(' ', c.cc_street_number, c.cc_street_name, c.cc_street_type, c.cc_suite_number) AS full_address,
  length(concat_ws(' ', c.cc_street_number, c.cc_street_name, c.cc_street_type, c.cc_suite_number)) AS address_len,
  (SELECT array_join(array_sort(array_agg(DISTINCT replace(lower(i.i_product_name), ' ', '-'))), '|')
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE cs.cs_call_center_sk = c.cc_call_center_sk
  ) AS product_names_hyphenated,
  (SELECT COUNT(DISTINCT element_at(split(cust.c_email_address, '@'), 2))
   FROM catalog_sales cs
   JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
   WHERE cs.cs_call_center_sk = c.cc_call_center_sk
  ) AS distinct_customer_email_domains,
  (SELECT COUNT(*)
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_call_center_sk = c.cc_call_center_sk
     AND regexp_like(lower(p.p_promo_name), 'discount')
  ) AS discount_promo_sales_count,
  (SELECT coalesce(SUM(cs.cs_net_paid), 0)
   FROM catalog_sales cs
   WHERE cs.cs_call_center_sk = c.cc_call_center_sk
  ) AS total_net_paid,
  regexp_extract(c.cc_manager, '([0-9]+)', 1) AS manager_digits_extracted,
  reverse(c.cc_zip) AS rev_zip,
  regexp_replace(c.cc_manager, '[^A-Za-z0-9]', '') AS manager_alnum
FROM call_center c
ORDER BY c.cc_call_center_id
