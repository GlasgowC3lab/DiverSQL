WITH unified AS (
  SELECT
    s.s_store_name AS channel,
    concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_full_name,
    reverse(concat_ws(' ', c.c_first_name, c.c_last_name)) AS rev_cust_full_name,
    lower(regexp_extract(c.c_email_address, '^([^@]+)', 1)) AS email_local_part,
    substr(lower(regexp_extract(c.c_email_address, '@(.+)$', 1)), 1, 1) AS first_email_char,
    lower(regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_domain,
    lower(regexp_replace(concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip), '\\s+', ' ')) AS cust_norm_address,
    lower(i.i_brand) || '-' || lower(i.i_class) || '-' || lower(i.i_category) AS product_key,
    lower(regexp_replace(i.i_item_desc, '[^a-z0-9 ]', '')) AS item_desc_clean,
    ss.ss_net_paid AS sales_amount,
    CAST(NULL AS BIGINT) AS url_length,
    CAST(NULL AS varchar) AS web_domain,
    cardinality(split(lower(i.i_item_desc), ' ')) AS item_desc_word_cnt
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE ss.ss_net_paid > 0

  UNION ALL

  SELECT
    'WEB' AS channel,
    concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_full_name,
    reverse(concat_ws(' ', c.c_first_name, c.c_last_name)) AS rev_cust_full_name,
    lower(regexp_extract(c.c_email_address, '^([^@]+)', 1)) AS email_local_part,
    substr(lower(regexp_extract(c.c_email_address, '@(.+)$', 1)), 1, 1) AS first_email_char,
    lower(regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_domain,
    lower(regexp_replace(concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip), '\\s+', ' ')) AS cust_norm_address,
    lower(i.i_brand) || '-' || lower(i.i_class) || '-' || lower(i.i_category) AS product_key,
    lower(regexp_replace(i.i_item_desc, '[^a-z0-9 ]', '')) AS item_desc_clean,
    ws.ws_net_paid AS sales_amount,
    length(wp.wp_url) AS url_length,
    regexp_extract(wp.wp_url, 'https?://([^/]+)', 1) AS web_domain,
    cardinality(split(lower(i.i_item_desc), ' ')) AS item_desc_word_cnt
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE ws.ws_net_paid > 0
),
agg AS (
  SELECT
    channel,
    cust_full_name,
    rev_cust_full_name,
    email_local_part,
    first_email_char,
    email_domain,
    cust_norm_address,
    item_desc_clean,
    SUM(sales_amount) AS total_sales,
    MAX(url_length) AS max_url_length,
    COUNT(DISTINCT web_domain) AS distinct_web_domains,
    AVG(item_desc_word_cnt) AS avg_item_desc_word_cnt,
    array_join(array_agg(DISTINCT product_key), ',') AS distinct_product_keys,
    SUM(CASE WHEN regexp_like(item_desc_clean, '\\bpromo\\b') THEN 1 ELSE 0 END) AS promo_word_occurrences
  FROM unified
  GROUP BY
    channel,
    cust_full_name,
    rev_cust_full_name,
    email_local_part,
    first_email_char,
    email_domain,
    cust_norm_address,
    item_desc_clean
  HAVING SUM(sales_amount) > 1000
)
SELECT
  channel,
  cust_full_name,
  rev_cust_full_name,
  email_local_part,
  first_email_char,
  email_domain,
  cust_norm_address,
  item_desc_clean,
  total_sales,
  max_url_length,
  distinct_web_domains,
  avg_item_desc_word_cnt,
  distinct_product_keys,
  promo_word_occurrences,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS channel_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
