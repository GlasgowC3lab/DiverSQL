WITH sales_data AS (
 SELECT
   cs.cs_order_number,
   cs.cs_quantity,
   cs.cs_net_paid,
   i.i_item_sk,
   i.i_product_name,
   i.i_item_desc,
   i.i_color,
   i.i_size,
   p.p_promo_name,
   cc.cc_name,
   cc.cc_hours,
   cp.cp_description,
   c.c_email_address,
   wp.wp_url,
   regexp_replace(lower(trim(i.i_product_name)), '[^a-z0-9]+', '-') AS product_slug,
   lower(trim(p.p_promo_name)) AS promo_name_clean,
   regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
   regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS url_domain,
   replace(i.i_item_desc, ' ', '_') AS desc_underscored,
   cardinality(split(i.i_item_desc, ' ')) AS desc_word_count,
   length(i.i_item_desc) AS desc_len,
   element_at(split(cc.cc_hours, '-'), 1) AS cc_hour_start,
   element_at(split(cc.cc_hours, '-'), 2) AS cc_hour_end,
   substr(i.i_color, 1, 2) AS color_prefix,
   substr(i.i_size, 1, 1) AS size_prefix,
   concat_ws('_', regexp_replace(lower(trim(i.i_product_name)), '[^a-z0-9]+', '-'), regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)) AS slug_email_key
 FROM catalog_sales cs
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
 LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
 LEFT JOIN web_page wp ON cp.cp_department = wp.wp_type
 WHERE c.c_email_address IS NOT NULL
   AND wp.wp_url IS NOT NULL
),
aggregated AS (
 SELECT
   product_slug,
   promo_name_clean,
   email_domain,
   url_domain,
   slug_email_key,
   cc_hour_start,
   cc_hour_end,
   desc_underscored,
   desc_word_count,
   desc_len,
   color_prefix,
   size_prefix,
   count(*) AS sales_transactions,
   sum(cs_quantity) AS total_quantity,
   sum(cs_net_paid) AS total_net_paid,
   avg(cs_net_paid) AS avg_net_paid,
   max(CASE WHEN cs_net_paid > 0 THEN cs_net_paid END) AS max_positive_net_paid
 FROM sales_data
 GROUP BY
   product_slug,
   promo_name_clean,
   email_domain,
   url_domain,
   slug_email_key,
   cc_hour_start,
   cc_hour_end,
   desc_underscored,
   desc_word_count,
   desc_len,
   color_prefix,
   size_prefix
 HAVING count(*) > 5
)
SELECT
  product_slug,
  promo_name_clean,
  email_domain,
  url_domain,
  slug_email_key,
  cc_hour_start,
  cc_hour_end,
  desc_underscored,
  desc_word_count,
  desc_len,
  color_prefix,
  size_prefix,
  sales_transactions,
  total_quantity,
  total_net_paid,
  avg_net_paid,
  max_positive_net_paid,
  row_number() OVER (PARTITION BY product_slug ORDER BY total_net_paid DESC) AS rank_by_net
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
