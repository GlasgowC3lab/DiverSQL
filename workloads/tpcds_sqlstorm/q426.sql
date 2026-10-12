WITH sales_strings AS (
 SELECT
   ss.ss_store_sk,
   i.i_item_sk,
   i.i_product_name,
   i.i_item_id,
   i.i_brand,
   i.i_color,
   length(i.i_product_name) AS name_len,
   cardinality(split(i.i_product_name, ' ')) AS name_word_cnt,
   regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '') AS name_alnum,
   lower(i.i_product_name) AS name_lower,
   substring(i.i_item_id, 1, 3) AS id_prefix,
   regexp_extract(i.i_item_id, '([0-9]+)', 1) AS id_digits,
   concat_ws('|', i.i_brand, i.i_color, i.i_product_name) AS composite_str,
   length(concat(i.i_brand, i.i_color, i.i_product_name)) AS composite_len,
   ss.ss_net_paid AS net_paid
 FROM store_sales ss
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
)
SELECT
  s.s_store_id,
  s.s_store_name,
  count(*) AS total_sales,
  sum(net_paid) AS total_net_paid,
  avg(name_len) AS avg_name_len,
  avg(name_word_cnt) AS avg_name_word_cnt,
  avg(length(id_digits)) AS avg_id_digit_len,
  max(composite_len) AS max_composite_len,
  cardinality(array_distinct(regexp_extract_all(array_join(array_agg(name_lower), ''), '.'))) AS distinct_char_cnt,
  regexp_replace(array_join(array_agg(name_alnum), ''), '(.)\\1+', '$1') AS deduped_alnum_concat,
  sum(CASE WHEN regexp_like(name_alnum, '^[0-9]+$') THEN 1 ELSE 0 END) AS cnt_names_all_digits,
  array_join(array_sort(array_distinct(array_agg(id_prefix))), ',') AS distinct_id_prefixes
FROM sales_strings
JOIN store s ON s.s_store_sk = sales_strings.ss_store_sk
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_net_paid DESC
LIMIT 20
