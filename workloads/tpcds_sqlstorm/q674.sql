SELECT
  s.s_store_id,
  s.s_store_name,
  lower(trim(s.s_store_name)) AS store_name_clean,
  concat_ws(' | ', s.s_manager, s.s_market_manager) AS manager_chain,
  s.s_state,
  s.s_city,
  concat(upper(substring(s.s_city, 1, 1)), lower(substring(s.s_city, 2))) AS city_proper,
  concat('Store located at ', s.s_street_number, ' ', s.s_street_name, ', ', s.s_city, ', ', s.s_state, ' ', s.s_zip) AS full_address,
  i.i_item_id,
  i.i_product_name,
  regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '') AS product_name_alnum,
  length(i.i_product_name) AS product_name_len,
  cardinality(split(i.i_product_name, ' ')) AS product_word_count,
  substring(i.i_product_name, 1, 10) AS product_name_prefix,
  i.i_brand,
  lower(i.i_brand) AS brand_lower,
  upper(i.i_brand) AS brand_upper,
  concat_ws('-', i.i_brand, i.i_class, i.i_category) AS brand_class_category,
  ss.ss_quantity,
  ss.ss_net_paid,
  ss.ss_net_paid_inc_tax,
  ss.ss_net_profit,
  format('Ticket-%010d', ss.ss_ticket_number) AS formatted_ticket,
  concat_ws(' ', c.c_first_name, c.c_last_name) AS customer_full_name,
  lower(c.c_email_address) AS email_lower,
  regexp_replace(c.c_email_address, '([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+)\\.([A-Za-z]{2,})', '$1@masked.$3') AS email_masked,
  length(regexp_replace(c.c_email_address, '\\s', '')) AS email_len_no_spaces,
  substring(c.c_login, 1, 3) AS login_prefix,
  replace(c.c_preferred_cust_flag, 'Y', 'YES') AS pref_cust_flag,
  concat_ws('_',
    lower(regexp_replace(i.i_product_name, '\\s+', '_')),
    lower(regexp_replace(s.s_store_name, '\\s+', '_'))
  ) AS product_store_key,
  sum(ss.ss_net_paid) OVER (
    PARTITION BY concat_ws('_',
      lower(regexp_replace(i.i_product_name, '\\s+', '_')),
      lower(regexp_replace(s.s_store_name, '\\s+', '_'))
    )
  ) AS total_net_paid_by_product_store,
  sum(ss.ss_quantity) OVER (
    PARTITION BY concat_ws('_',
      lower(regexp_replace(i.i_product_name, '\\s+', '_')),
      lower(regexp_replace(s.s_store_name, '\\s+', '_'))
    )
  ) AS total_quantity_by_product_store,
  reverse(i.i_item_id) AS reversed_item_id,
  array_join(split(i.i_product_name, ' '), '-') AS product_name_hyphens,
  replace(i.i_color, 'Red', 'Crimson') AS color_replaced,
  CASE
    WHEN regexp_like(i.i_product_name, '^.*[0-9]{3,}.*$') THEN 'Contains3DigitSeq'
    ELSE 'No3DigitSeq'
  END AS product_3digit_flag,
  CASE
    WHEN regexp_like(s.s_store_name, '(?i)store') THEN 'HasStoreKeyword'
    ELSE 'NoStoreKeyword'
  END AS store_name_flag,
  d.d_year,
  d.d_month_seq,
  d.d_day_name,
  d.d_date
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE s.s_state = 'CA'
  AND d.d_year BETWEEN 1999 AND 2002
  AND regexp_like(i.i_product_name, '[A-Za-z]')
  AND regexp_like(c.c_email_address, '@')
ORDER BY s.s_store_id, i.i_item_id
LIMIT 1000
