SELECT
  CAST(d.d_date AS varchar) AS sales_date,
  concat_ws('||',
    replace(upper(cc.cc_name), ' ', '_'),
    regexp_replace(cp.cp_description, '[^A-Za-z0-9 ]', ''),
    translate(substr(i.i_product_name, 1, 15), 'AEIOUaeiou', ''),
    replace(lower(i.i_color), ' ', '-'),
    upper(i.i_size),
    reverse(cp.cp_type),
    trim(lower(cc.cc_class))
  ) AS complex_key,
  length(cc.cc_name) AS cc_name_len,
  length(cp.cp_description) AS cp_desc_len,
  cardinality(split(i.i_product_name, ' ')) AS prod_name_word_cnt,
  array_join(filter(split(i.i_product_name, ' '), w -> length(w) > 4), '#') AS long_word_concat,
  regexp_extract(i.i_product_name, '(\\d+)', 1) AS numeric_part,
  count(*) AS txn_cnt,
  sum(cs.cs_net_paid) AS total_net_paid,
  avg(cs.cs_quantity) AS avg_quantity,
  max(cs.cs_net_paid) AS max_net_paid,
  min(cs.cs_net_paid) AS min_net_paid
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cs.cs_net_paid > 0
  AND d.d_year = 2001
  AND regexp_like(i.i_product_name, '(?i)pro|max')
GROUP BY
  CAST(d.d_date AS varchar),
  concat_ws('||',
    replace(upper(cc.cc_name), ' ', '_'),
    regexp_replace(cp.cp_description, '[^A-Za-z0-9 ]', ''),
    translate(substr(i.i_product_name, 1, 15), 'AEIOUaeiou', ''),
    replace(lower(i.i_color), ' ', '-'),
    upper(i.i_size),
    reverse(cp.cp_type),
    trim(lower(cc.cc_class))
  ),
  length(cc.cc_name),
  length(cp.cp_description),
  cardinality(split(i.i_product_name, ' ')),
  array_join(filter(split(i.i_product_name, ' '), w -> length(w) > 4), '#'),
  regexp_extract(i.i_product_name, '(\\d+)', 1)
HAVING count(*) > 10
ORDER BY total_net_paid DESC
LIMIT 50
