WITH cc_agg AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    concat(cc.cc_city, ', ', cc.cc_state) AS cc_location,
    array_agg(DISTINCT split_part(c.c_email_address, '@', 2)) AS email_domains,
    array_agg(DISTINCT i.i_product_name) AS product_names_arr,
    max(CASE WHEN regexp_like(i.i_product_name, '(?i)promo') THEN 1 ELSE 0 END) AS has_promo_product
  FROM call_center cc
  JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_city, cc.cc_state
)
SELECT
  cc_call_center_id,
  cc_name,
  lower(cc_name) AS cc_name_lower,
  replace(cc_name, ' ', '_') AS cc_name_underscored,
  reverse(cc_name) AS cc_name_reverse,
  cc_location,
  length(cc_name) AS cc_name_len,
  array_join(array_sort(email_domains), ', ') AS email_domains_str,
  cardinality(email_domains) AS email_domain_count,
  product_names_arr,
  has_promo_product
FROM cc_agg
