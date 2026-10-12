WITH email_features AS (
  SELECT
    c.c_customer_sk,
    lower(c.c_email_address) AS email_lc,
    lower(split_part(split_part(c.c_email_address, '@', 2), '.', 1)) AS email_domain,
    length(split_part(c.c_email_address, '@', 1)) AS email_user_len
  FROM customer c
),
address_features AS (
  SELECT
    ca.ca_address_sk,
    upper(substr(ca.ca_city, 1, 3)) AS city_prefix,
    upper(ca.ca_state) AS state_code,
    concat_ws('-', upper(substr(ca.ca_city, 1, 3)), ca.ca_state) AS loc_code,
    length(ca.ca_zip) AS zip_len,
    replace(lower(ca.ca_city), ' ', '_') AS city_norm
  FROM customer_address ca
),
item_features AS (
  SELECT
    i.i_item_sk,
    replace(lower(i.i_brand), ' ', '_') AS brand_norm,
    regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '') AS desc_clean,
    length(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS desc_clean_len
  FROM item i
),
call_center_features AS (
  SELECT
    cc.cc_call_center_sk,
    replace(lower(cc.cc_name), ' ', '_') AS call_center_norm
  FROM call_center cc
),
store_features AS (
  SELECT
    s.s_store_sk,
    concat_ws('-', upper(substr(s.s_city, 1, 3)), s.s_state) AS store_loc_code,
    replace(lower(s.s_store_name), ' ', '_') AS store_name_norm
  FROM store s
),
sales_store AS (
  SELECT
    'store' AS sales_channel,
    ss.ss_sold_date_sk AS sold_date_sk,
    d.d_year,
    d.d_day_name,
    ss.ss_item_sk AS ss_item_sk,
    ss.ss_customer_sk AS ss_customer_sk,
    ss.ss_store_sk AS ss_store_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    CAST(null AS integer) AS call_center_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
),
sales_web AS (
  SELECT
    'web' AS sales_channel,
    ws.ws_sold_date_sk AS sold_date_sk,
    d.d_year,
    d.d_day_name,
    ws.ws_item_sk AS ss_item_sk,
    ws.ws_bill_customer_sk AS ss_customer_sk,
    CAST(null AS integer) AS ss_store_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    CAST(null AS integer) AS call_center_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
sales_catalog AS (
  SELECT
    'catalog' AS sales_channel,
    cs.cs_sold_date_sk AS sold_date_sk,
    d.d_year,
    d.d_day_name,
    cs.cs_item_sk AS ss_item_sk,
    cs.cs_bill_customer_sk AS ss_customer_sk,
    CAST(null AS integer) AS ss_store_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_call_center_sk AS call_center_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
),
all_sales AS (
  SELECT * FROM sales_store
  UNION ALL
  SELECT * FROM sales_web
  UNION ALL
  SELECT * FROM sales_catalog
),
sales_detail AS (
  SELECT
    a.sales_channel,
    a.d_year,
    a.d_day_name,
    a.quantity,
    a.net_paid,
    a.net_profit,
    itf.brand_norm,
    ef.email_domain,
    coalesce(st.store_loc_code, af.loc_code) AS loc_code,
    length(ef.email_lc) AS email_len,
    (length(ef.email_domain) - length(replace(ef.email_domain, '.', ''))) AS email_dot_count,
    length(regexp_replace(lower(itf.desc_clean), '[^aeiou]', '')) AS desc_vowel_count,
    cf.call_center_norm,
    concat_ws('|', itf.brand_norm, ef.email_domain, coalesce(st.store_loc_code, af.loc_code), lower(a.d_day_name), coalesce(cf.call_center_norm, 'none')) AS grouping_key
  FROM all_sales a
  LEFT JOIN email_features ef ON a.ss_customer_sk = ef.c_customer_sk
  LEFT JOIN customer cust ON a.ss_customer_sk = cust.c_customer_sk
  LEFT JOIN address_features af ON cust.c_current_addr_sk = af.ca_address_sk
  LEFT JOIN item_features itf ON a.ss_item_sk = itf.i_item_sk
  LEFT JOIN call_center_features cf ON a.call_center_sk = cf.cc_call_center_sk
  LEFT JOIN store_features st ON a.ss_store_sk = st.s_store_sk
)
SELECT
  sales_channel,
  grouping_key,
  sum(net_paid) AS total_net_paid,
  sum(net_profit) AS total_net_profit,
  sum(quantity) AS total_quantity,
  avg(email_len) AS avg_email_len,
  avg(email_dot_count) AS avg_email_dot_cnt,
  avg(desc_vowel_count) AS avg_desc_vowel_cnt,
  count(*) AS txn_cnt
FROM sales_detail
GROUP BY
  sales_channel,
  grouping_key
ORDER BY total_net_paid DESC
LIMIT 100
