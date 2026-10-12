SELECT
  cc.cc_call_center_id,
  lower(cc.cc_name) AS lc_name,
  upper(cc.cc_manager) AS uc_manager,
  length(cc.cc_hours) AS hours_len,
  regexp_replace(cc.cc_hours, '[^0-9]', '') AS hours_digits,
  trim(cc.cc_city) AS trimmed_city,
  replace(cc.cc_city, ' ', '_') AS city_underscored,
  concat(cc.cc_state, '-', cc.cc_zip) AS state_zip,
  substr(cc.cc_street_name, 1, 5) AS street_name_prefix,
  array_join(split(cc.cc_name, ' '), '|') AS name_words_pipe,
  cardinality(split(cc.cc_hours, ':')) AS hours_parts,
  CASE WHEN regexp_like(cc.cc_name, '(?i)center|dept') THEN 1 ELSE 0 END AS has_center_or_dept,
  lower(cp.cp_description) AS cp_desc_lc,
  length(cp.cp_description) AS cp_desc_len,
  replace(cp.cp_description, ' ', '') AS cp_desc_no_spaces,
  upper(cp.cp_type) AS cp_type_upper,
  array_join(split(cp.cp_type, '_'), '|') AS cp_type_words,
  sum(cs.cs_ext_sales_price) AS total_sales,
  count(distinct cs.cs_item_sk) AS distinct_items
FROM call_center cc
JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE lower(cc.cc_name) LIKE '%center%'
GROUP BY
  cc.cc_call_center_id,
  lower(cc.cc_name),
  upper(cc.cc_manager),
  length(cc.cc_hours),
  regexp_replace(cc.cc_hours, '[^0-9]', ''),
  trim(cc.cc_city),
  replace(cc.cc_city, ' ', '_'),
  concat(cc.cc_state, '-', cc.cc_zip),
  substr(cc.cc_street_name, 1, 5),
  array_join(split(cc.cc_name, ' '), '|'),
  cardinality(split(cc.cc_hours, ':')),
  CASE WHEN regexp_like(cc.cc_name, '(?i)center|dept') THEN 1 ELSE 0 END,
  lower(cp.cp_description),
  length(cp.cp_description),
  replace(cp.cp_description, ' ', ''),
  upper(cp.cp_type),
  array_join(split(cp.cp_type, '_'), '|')
HAVING sum(cs.cs_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
