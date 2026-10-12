WITH processed AS (
  SELECT
    s.s_store_sk,
    s.s_store_id,
    s.s_store_name,
    reverse(s.s_store_name) AS store_name_rev,
    length(s.s_store_name) AS store_name_len,
    regexp_replace(s.s_store_name, '[^A-Z]', '') AS store_name_initials,
    concat(substr(s.s_city, 1, 3), '-', s.s_state, '-', s.s_zip) AS store_loc_code,
    upper(s.s_city) AS city_upper,
    length(s.s_city) AS city_length,
    format_datetime(d.d_date, 'yyyy-MM') AS month,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    lower(i.i_item_desc) AS item_desc_lower,
    replace(i.i_item_desc, ' ', '-') AS item_desc_hyphen,
    lower(replace(i.i_item_desc, ' ', '-')) AS item_desc_slug,
    length(i.i_item_desc) AS item_desc_len,
    length(regexp_replace(lower(i.i_item_desc), '[^aeiou]', '')) AS item_desc_vowel_cnt,
    i.i_brand,
    i.i_class,
    i.i_category,
    i.i_color,
    i.i_size,
    i.i_units,
    concat_ws('-', i.i_brand, i.i_class, i.i_category) AS product_hierarchy,
    replace(lower(i.i_color), ' ', '-') AS color_slug,
    replace(lower(i.i_size), ' ', '-') AS size_slug,
    replace(lower(i.i_units), ' ', '-') AS units_slug,
    length(i.i_product_name) AS prod_name_len,
    length(regexp_replace(lower(i.i_product_name), '[^aeiou]', '')) AS vowel_cnt,
    length(regexp_replace(i.i_product_name, '[^0-9]', '')) AS digit_cnt,
    CASE WHEN regexp_like(lower(i.i_product_name), 'promo') THEN 1 ELSE 0 END AS promo_flag,
    c.c_customer_id,
    concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS cust_full_name,
    ss.ss_net_paid,
    ss.ss_quantity,
    ss.ss_ticket_number AS ticket_number
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
)
SELECT
    store_loc_code,
    month,
    count(DISTINCT s_store_id) AS distinct_stores,
    sum(ss_net_paid) AS total_net_paid,
    sum(ss_quantity) AS total_quantity,
    sum(prod_name_len) AS total_prod_name_len,
    sum(vowel_cnt) AS total_prod_vowel_cnt,
    sum(digit_cnt) AS total_prod_digit_cnt,
    sum(item_desc_len) AS total_item_desc_len,
    sum(item_desc_vowel_cnt) AS total_item_desc_vowel_cnt,
    sum(promo_flag) AS total_promo_products,
    approx_distinct(cust_full_name) AS approx_distinct_customers,
    array_agg(DISTINCT product_hierarchy) AS product_hierarchies,
    max(concat_ws('_', color_slug, size_slug, units_slug)) AS sample_product_slug,
    max(store_name_rev) AS sample_store_name_rev,
    max(store_name_initials) AS sample_store_initials,
    max(city_upper) AS sample_city_upper
FROM processed
GROUP BY store_loc_code, month
ORDER BY month, store_loc_code
