WITH item_strings AS (
  SELECT
    i_item_sk,
    concat_ws(' ',
      i_product_name,
      i_brand,
      i_class,
      i_category,
      coalesce(i_color, ''),
      coalesce(i_size, ''),
      coalesce(i_formulation, '')
    ) AS full_desc,
    lower(i_product_name) AS lower_product_name,
    replace(i_product_name, ' ', '_') AS product_name_underscore
  FROM item
),
sales_strings AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    ss.ss_sold_date_sk AS ss_date_sk,
    ws.ws_sold_date_sk AS ws_date_sk,
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_quantity,
    i.full_desc,
    length(i.full_desc) AS desc_len,
    cardinality(split(i.full_desc, ' ')) AS token_count,
    regexp_replace(i.full_desc, '[^A-Za-z0-9]', '') AS alphanum_desc,
    upper(regexp_replace(i.full_desc, '\\s+', '_')) AS normalized_desc,
    reverse(i.lower_product_name) AS rev_lower_name,
    substr(i.lower_product_name, 1, 5) AS prefix,
    substr(i.lower_product_name, -5) AS suffix
  FROM catalog_sales cs
  JOIN item_strings i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN store_sales ss ON cs.cs_order_number = ss.ss_ticket_number AND cs.cs_item_sk = ss.ss_item_sk
  LEFT JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number AND cs.cs_item_sk = ws.ws_item_sk
),
joined_data AS (
  SELECT
    s.*,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    d.d_day_name AS day_name,
    d.d_holiday AS holiday,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    lower(c.c_email_address) AS email_lower,
    regexp_replace(c.c_email_address, '[^a-z0-9@.]', '') AS email_clean,
    concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
    length(c.c_last_name) AS last_name_len,
    substring(c.c_login, 1, 3) AS login_prefix
  FROM sales_strings s
  LEFT JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON s.cs_order_number % 100000 = c.c_customer_sk % 100000
)
SELECT
  concat_ws(' | ', jd.full_desc, jd.full_name, jd.email_clean) AS composite_key,
  jd.desc_len,
  jd.token_count,
  jd.alphanum_desc,
  jd.normalized_desc,
  jd.rev_lower_name,
  jd.prefix,
  jd.suffix,
  jd.year,
  jd.month_seq,
  jd.day_name,
  jd.holiday,
  COUNT(*) AS txn_count,
  SUM(jd.cs_ext_sales_price) AS total_sales,
  AVG(jd.cs_ext_discount_amt) AS avg_discount,
  SUM(jd.cs_quantity) AS total_quantity,
  MIN(jd.last_name_len) AS min_last_name_len,
  MAX(jd.last_name_len) AS max_last_name_len,
  COUNT(DISTINCT jd.c_customer_sk) AS distinct_customers,
  approx_percentile(jd.cs_ext_sales_price, 0.5) AS median_sales_price
FROM joined_data jd
WHERE regexp_like(jd.normalized_desc, '^.*[A-Z]{3}.*$')
GROUP BY
  concat_ws(' | ', jd.full_desc, jd.full_name, jd.email_clean),
  jd.full_desc,
  jd.full_name,
  jd.email_clean,
  jd.desc_len,
  jd.token_count,
  jd.alphanum_desc,
  jd.normalized_desc,
  jd.rev_lower_name,
  jd.prefix,
  jd.suffix,
  jd.year,
  jd.month_seq,
  jd.day_name,
  jd.holiday
HAVING COUNT(*) > 100
ORDER BY total_sales DESC
LIMIT 100
