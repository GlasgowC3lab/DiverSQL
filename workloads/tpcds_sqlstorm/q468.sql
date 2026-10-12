SELECT 
  concat_ws('|', lower(regexp_replace(concat(c.c_first_name, ' ', c.c_last_name), '\\s+', '')), substr(i.i_product_name, 1, 5), upper(substr(cc.cc_city, 1, 3))) AS composite_key,
  length(regexp_replace(i.i_item_desc, '[^a-zA-Z]', '')) AS alpha_char_count,
  cardinality(split(i.i_item_desc, '\\s+')) AS word_count,
  cardinality(regexp_extract_all(i.i_item_desc, '[AEIOUaeiou]')) AS vowel_count,
  length(regexp_replace(lower(c.c_email_address), '[^a-z0-9@.]', '')) AS clean_email_len,
  split_part(c.c_email_address, '@', 2) AS email_domain,
  sum(ss.ss_ext_sales_price) AS total_sales,
  avg(ss.ss_net_profit) AS avg_profit,
  count(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
  array_join(array_agg(DISTINCT p.p_promo_name), ', ') AS promo_names
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN call_center cc ON s.s_market_id = cc.cc_mkt_id
WHERE d.d_year = 2001 
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY 1,2,3,4,5,6
HAVING sum(ss.ss_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 50
