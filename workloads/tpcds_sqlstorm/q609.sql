WITH sales_strings AS (
  SELECT
    d.d_date,
    i.i_category,
    ss.ss_ticket_number,
    lower(i.i_product_name) AS product_name_lower,
    upper(i.i_brand) AS brand_upper,
    regexp_replace(i.i_item_desc, '\\s+', ' ') AS item_desc_norm,
    length(i.i_item_desc) AS item_desc_len,
    trim(i.i_color) AS color_trim,
    replace(i.i_color, ' ', '_') AS color_underscore,
    element_at(split(i.i_size, '-'), 1) AS size_prefix,
    concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS customer_name,
    upper(substr(c.c_email_address, 1, strpos(c.c_email_address, '@') - 1)) AS email_user_upper,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    translate(c.c_email_address, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') AS email_lower,
    s.s_store_name AS store_name,
    ss.ss_net_paid,
    ss.ss_net_paid_inc_tax,
    ss.ss_net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2002
)
SELECT
  d_date,
  i_category,
  format('%s_%s', CAST(d_date AS VARCHAR), i_category) AS date_category_key,
  count(*) AS sales_count,
  sum(ss_net_paid) AS total_net_paid,
  sum(ss_net_profit) AS total_profit,
  avg(item_desc_len) AS avg_desc_len,
  array_join(array_agg(DISTINCT brand_upper), ',') AS distinct_brands,
  array_join(array_agg(DISTINCT color_underscore), ',') AS distinct_colors,
  max(email_domain) FILTER (WHERE email_domain IS NOT NULL) AS max_email_domain,
  min(email_user_upper) FILTER (WHERE email_user_upper IS NOT NULL) AS min_email_user,
  concat_ws(' | ', array_join(array_agg(DISTINCT size_prefix), ','), array_join(array_agg(DISTINCT product_name_lower), ',')) AS size_and_products
FROM sales_strings
GROUP BY d_date, i_category
ORDER BY d_date, i_category
LIMIT 100
