SELECT
  d.d_year,
  d.d_month_seq,
  upper(substr(cc.cc_name, 1, 10)) || '_' || lower(substr(cc.cc_manager, 1, 5)) AS cc_name_manager_code,
  regexp_replace(cp.cp_description, '\\s+', ' ') AS cp_desc_clean,
  array_join(slice(split(i.i_item_desc, '\\s+'), 1, 3), ' ') AS item_desc_first3,
  cardinality(split(i.i_item_desc, '\\s+')) AS item_desc_word_cnt,
  concat_ws('-', replace(i.i_brand, ' ', ''), replace(i.i_color, ' ', ''), lower(i.i_size)) AS brand_color_size_key,
  replace(w.w_warehouse_name, ' ', '_') AS warehouse_name_underscored,
  lower(
    concat_ws('|',
      regexp_replace(cc.cc_city, '[^a-zA-Z]', ''),
      regexp_replace(i.i_category, '\\s+', ''),
      substr(p.p_promo_name, 1, 4),
      CAST(d.d_year AS VARCHAR)
    )
  ) AS composite_key,
  regexp_replace(p.p_promo_name, '[AEIOUaeiou]', '') AS promo_name_no_vowels,
  concat_ws('::',
    cc.cc_manager,
    cp.cp_type,
    i.i_product_name,
    p.p_promo_id,
    w.w_warehouse_name,
    d.d_quarter_name
  ) AS long_dim_string,
  length(cc.cc_hours) AS cc_hours_len,
  sum(cs.cs_ext_sales_price) AS total_sales,
  avg(cs.cs_net_profit) AS avg_profit,
  count(*) AS txn_count,
  regexp_extract(d.d_date_id, '(\\d{4})\\d{2}\\d{2}', 1) AS extracted_year_from_date_id,
  format('%.2f', sum(cs.cs_ext_sales_price)) AS total_sales_formatted,
  regexp_replace(lower(cp.cp_description), 'sale', 'transaction') AS cp_desc_search_replace
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY
  d.d_year,
  d.d_month_seq,
  cc.cc_name,
  cc.cc_manager,
  cc.cc_city,
  cc.cc_hours,
  cp.cp_description,
  cp.cp_type,
  i.i_item_desc,
  i.i_brand,
  i.i_color,
  i.i_size,
  i.i_product_name,
  i.i_category,
  p.p_promo_name,
  p.p_promo_id,
  w.w_warehouse_name,
  d.d_quarter_name,
  d.d_date_id
