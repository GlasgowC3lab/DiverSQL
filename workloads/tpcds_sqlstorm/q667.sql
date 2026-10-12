WITH cleaned_data AS (
 SELECT
    s.s_store_name AS store_name,
    s.s_city,
    s.s_state,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city AS cust_city,
    ca.ca_state AS cust_state,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    lower(trim(concat(c.c_first_name, ' ', c.c_last_name))) AS normalized_name,
    regexp_replace(regexp_extract(c.c_email_address, '^([^@]+)', 1), '[^a-z0-9]', '') AS email_local_clean,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    substr(reverse(i.i_item_desc), 1, 30) AS reversed_desc_30,
    (length(i.i_item_desc) - length(replace(i.i_item_desc, 'e', ''))) AS count_e,
    ss.ss_quantity AS ss_quantity,
    ss.ss_net_paid AS ss_net_paid,
    ss.ss_ext_sales_price AS ss_ext_sales_price
 FROM store_sales ss
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
 LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 WHERE c.c_email_address IS NOT NULL
)
SELECT
  store_name,
  concat(s_city, ', ', s_state) AS store_location,
  email_domain,
  normalized_name,
  email_local_clean,
  i_item_id AS item_id,
  i_product_name AS product_name,
  reversed_desc_30,
  count_e,
  sum(ss_quantity) AS total_quantity,
  sum(ss_net_paid) AS total_net_paid,
  sum(ss_ext_sales_price) AS total_ext_sales_price,
  avg(length(normalized_name) + length(email_domain)) AS avg_name_email_len,
  array_join(array_agg(DISTINCT substr(email_local_clean, 1, 5) || '_' || email_domain), ',') AS sample_local_domains
FROM cleaned_data
GROUP BY
  store_name,
  s_city,
  s_state,
  email_domain,
  normalized_name,
  email_local_clean,
  i_item_id,
  i_product_name,
  reversed_desc_30,
  count_e
HAVING sum(ss_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
