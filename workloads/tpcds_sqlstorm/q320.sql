WITH normalized_cc AS (
 SELECT
   cc_call_center_sk,
   lower(cc_name) AS cc_name_lc,
   regexp_replace(lower(cc_name), '[^a-z0-9]', '') AS cc_name_alpha,
   length(cc_name) AS cc_name_len,
   concat(cc_city, ', ', cc_state) AS cc_city_state,
   regexp_extract(cc_manager, '([A-Z][a-z]+)\\s+([A-Z][a-z]+)', 1) AS manager_first,
   regexp_extract(cc_manager, '([A-Z][a-z]+)\\s+([A-Z][a-z]+)', 2) AS manager_last
 FROM call_center
),
item_strings AS (
 SELECT
   i_item_sk,
   i_item_desc,
   lower(i_item_desc) AS i_desc_lc,
   replace(i_item_desc, '-', ' ') AS i_desc_spaced,
   regexp_replace(lower(i_item_desc), '[^a-z0-9\\s]', '') AS i_desc_clean,
   length(i_item_desc) AS i_desc_len,
   split(i_item_desc, '\\s+') AS i_desc_words,
   cardinality(split(i_item_desc, '\\s+')) AS i_desc_word_count
 FROM item
),
sales_strings AS (
 SELECT
   cs.cs_order_number,
   cs.cs_call_center_sk,
   cs.cs_item_sk,
   cs.cs_quantity,
   cs.cs_ext_sales_price,
   lower(c.c_first_name) AS cust_first_lc,
   lower(c.c_last_name) AS cust_last_lc,
   concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_full_name,
   regexp_replace(concat_ws(' ', c.c_first_name, c.c_last_name), '[aeiouAEIOU]', '*') AS cust_name_masked,
   length(c.c_email_address) AS email_len,
   regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$') AS email_valid
 FROM catalog_sales cs
 JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
),
joined AS (
 SELECT
   ncc.cc_call_center_sk,
   ncc.cc_name_alpha,
   ncc.cc_city_state,
   ncc.manager_last,
   it.i_item_sk,
   it.i_desc_lc,
   it.i_desc_clean,
   it.i_desc_len,
   it.i_desc_word_count,
   ss.cs_order_number,
   ss.cs_quantity,
   ss.cs_ext_sales_price,
   ss.cust_full_name,
   ss.cust_name_masked,
   ss.email_len,
   ss.email_valid
 FROM normalized_cc ncc
 JOIN sales_strings ss ON ncc.cc_call_center_sk = ss.cs_call_center_sk
 JOIN item_strings it ON ss.cs_item_sk = it.i_item_sk
 WHERE it.i_desc_clean IS NOT NULL
)
SELECT
  cc_name_alpha,
  cc_city_state,
  manager_last,
  total_sales,
  avg_quantity,
  avg_item_desc_len,
  avg_email_len,
  valid_email_cnt,
  total_rows,
  row_number() OVER (PARTITION BY cc_name_alpha ORDER BY total_sales DESC) AS rank_by_sales
FROM (
  SELECT
    cc_name_alpha,
    cc_city_state,
    manager_last,
    sum(cs_ext_sales_price) AS total_sales,
    avg(cs_quantity) AS avg_quantity,
    avg(i_desc_len) AS avg_item_desc_len,
    avg(email_len) AS avg_email_len,
    count_if(email_valid) AS valid_email_cnt,
    count(*) AS total_rows
  FROM joined
  GROUP BY cc_name_alpha, cc_city_state, manager_last
) t
ORDER BY total_sales DESC
LIMIT 100
