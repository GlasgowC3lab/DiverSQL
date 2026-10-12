WITH
customer_strings AS (
   SELECT
      c.c_customer_sk,
      c.c_current_addr_sk,
      concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
      lower(c.c_email_address) AS email_lower,
      split(c.c_email_address, '@')[2] AS email_domain,
      regexp_extract(c.c_email_address, '^([^@]+)@', 1) AS email_user,
      length(c.c_first_name) + length(c.c_last_name) AS name_len,
      substr(c.c_first_name, 1, 1) || '.' || lower(c.c_last_name) AS name_initials
   FROM customer c
),
address_strings AS (
   SELECT
      ca.ca_address_sk,
      concat_ws(' ',
                ca.ca_street_number,
                ca.ca_street_name,
                ca.ca_street_type,
                (CASE WHEN ca.ca_suite_number IS NOT NULL AND ca.ca_suite_number <> '' THEN concat('Suite', ca.ca_suite_number) ELSE '' END),
                ca.ca_city,
                ca.ca_state,
                ca.ca_zip) AS full_address,
      regexp_replace(ca.ca_zip, '\\D', '') AS zip_digits,
      length(ca.ca_zip) AS zip_len,
      lower(ca.ca_city) AS city_lower,
      CASE WHEN lower(ca.ca_city) LIKE '%city%' THEN 1 ELSE 0 END AS city_contains_city
   FROM customer_address ca
),
item_strings AS (
   SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_item_desc,
      lower(i.i_product_name) AS product_name_lower,
      regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '') AS product_name_alphanum,
      regexp_replace(i.i_item_desc, '\\s+', ' ') AS clean_desc,
      length(i.i_item_desc) AS desc_len,
      cardinality(split(i.i_item_desc, '\\s+')) AS word_count,
      concat(i.i_brand, ' ', i.i_class, ' ', i.i_category) AS brand_class_category,
      substr(i.i_product_name, 1, 10) AS product_name_prefix,
      length(replace(i.i_product_name, ' ', '')) AS product_name_no_spaces_len
   FROM item i
),
sales_union AS (
   SELECT
      cs.cs_bill_customer_sk AS customer_sk,
      d.d_year,
      d.d_moy AS d_month,
      cs.cs_net_paid AS net_paid,
      cs.cs_order_number AS order_number,
      i.i_item_sk,
      i.i_product_name,
      i.i_item_desc,
      'catalog' AS channel,
      cp.cp_type AS channel_type,
      cc.cc_name AS channel_name
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   UNION ALL
   SELECT
      ss.ss_customer_sk,
      d.d_year,
      d.d_moy AS d_month,
      ss.ss_net_paid,
      ss.ss_ticket_number,
      i.i_item_sk,
      i.i_product_name,
      i.i_item_desc,
      'store' AS channel,
      s.s_store_name AS channel_type,
      s.s_manager AS channel_name
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   UNION ALL
   SELECT
      ws.ws_bill_customer_sk,
      d.d_year,
      d.d_moy AS d_month,
      ws.ws_net_paid,
      ws.ws_order_number,
      i.i_item_sk,
      i.i_product_name,
      i.i_item_desc,
      'web' AS channel,
      wp.wp_type AS channel_type,
      wp.wp_url AS channel_name
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
),
agg_sales AS (
   SELECT
      su.customer_sk,
      su.d_year,
      su.d_month,
      sum(su.net_paid) AS total_net_paid,
      count(DISTINCT su.order_number) AS total_orders,
      count(DISTINCT su.i_item_sk) AS distinct_items,
      max_by(su.channel, su.net_paid) AS primary_channel,
      array_join(array_agg(DISTINCT coalesce(su.channel_type, '')), '|') AS channel_types,
      array_join(array_agg(DISTINCT coalesce(su.channel_name, '')), '|') AS channel_names
   FROM sales_union su
   GROUP BY su.customer_sk, su.d_year, su.d_month
),
top_item_per_cust_month AS (
   SELECT
      su.customer_sk,
      su.d_year,
      su.d_month,
      max_by(su.i_item_sk, su.net_paid) AS top_item_sk
   FROM sales_union su
   GROUP BY su.customer_sk, su.d_year, su.d_month
)
SELECT
   replace(cs.full_name, ' ', '_') AS name_underscore,
   cs.full_name,
   cs.name_initials,
   length(cs.full_name) AS full_name_len,
   cs.email_domain,
   cs.email_user,
   cs.email_lower,
   a.full_address,
   length(a.full_address) AS address_len,
   a.zip_digits,
   i.brand_class_category,
   i.word_count,
   i.product_name_prefix,
   i.product_name_no_spaces_len,
   agg.d_year,
   agg.d_month,
   agg.total_net_paid,
   agg.total_orders,
   agg.distinct_items,
   agg.channel_types,
   agg.channel_names,
   agg.primary_channel,
   row_number() OVER (PARTITION BY agg.d_year, agg.d_month ORDER BY agg.total_net_paid DESC) AS rank_by_sales
FROM agg_sales agg
JOIN customer_strings cs ON agg.customer_sk = cs.c_customer_sk
JOIN address_strings a ON cs.c_current_addr_sk = a.ca_address_sk
JOIN top_item_per_cust_month tm ON agg.customer_sk = tm.customer_sk AND agg.d_year = tm.d_year AND agg.d_month = tm.d_month
JOIN item_strings i ON i.i_item_sk = tm.top_item_sk
WHERE regexp_like(cs.email_domain, '\\.(com|net|org)$')
  AND a.city_contains_city = 1
  AND length(cs.email_lower) > 10
ORDER BY agg.d_year, agg.d_month, rank_by_sales
LIMIT 100
