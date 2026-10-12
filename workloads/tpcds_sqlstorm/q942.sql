WITH
item_data AS (
  SELECT
    i_item_sk,
    i_item_desc,
    i_product_name,
    i_color,
    i_category,
    i_class,
    i_brand,
    length(i_item_desc) AS raw_desc_len,
    regexp_replace(lower(i_item_desc), '[^a-z0-9]', '') AS clean_desc,
    upper(i_product_name) AS upper_name,
    concat(
      regexp_replace(lower(i_item_desc), '[^a-z0-9]', ''),
      '-',
      upper(i_product_name),
      '-',
      i_color,
      '-',
      i_category
    ) AS composite_key,
    length(concat(
      regexp_replace(lower(i_item_desc), '[^a-z0-9]', ''),
      '-',
      upper(i_product_name),
      '-',
      i_color,
      '-',
      i_category
    )) AS composite_len
  FROM item
),
customer_email_domain AS (
  SELECT
    c.c_customer_sk,
    lower(regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_domain,
    c.c_first_name,
    c.c_last_name
  FROM customer c
),
web_sales_enhanced AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_web_page_sk,
    ws.ws_promo_sk,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    d.d_day_name,
    c.c_customer_sk,
    ce.email_domain,
    it.composite_key,
    it.composite_len,
    replace(CAST(ws.ws_coupon_amt AS varchar), '.', '_') AS extra_string,
    substr(it.i_product_name, 1, 10) AS string_prefix,
    regexp_like(it.i_item_desc, '[0-9]') AS bool_flag,
    CASE
      WHEN it.i_color = 'Red' THEN 'R'
      WHEN it.i_color = 'Blue' THEN 'B'
      ELSE 'O'
    END AS code,
    concat_ws('|', c.c_first_name, c.c_last_name, ce.email_domain) AS tag
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_email_domain ce ON c.c_customer_sk = ce.c_customer_sk
  JOIN item_data it ON ws.ws_item_sk = it.i_item_sk
),
store_sales_enhanced AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_sales_price,
    ss.ss_net_paid,
    ss.ss_net_profit,
    ss.ss_store_sk,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    d.d_day_name,
    s.s_store_name,
    ce.email_domain,
    it.composite_key,
    it.composite_len,
    replace(CAST(ss.ss_ext_discount_amt AS varchar), '.', '-') AS extra_string,
    substr(it.i_product_name, -5) AS string_prefix,
    regexp_like(it.i_item_desc, '[AEIOU]') AS bool_flag,
    CASE
      WHEN s.s_state = 'CA' THEN 'WEST'
      WHEN s.s_state = 'NY' THEN 'EAST'
      ELSE 'OTHER'
    END AS code,
    concat_ws('::', s.s_store_name, it.i_category) AS tag
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_email_domain ce ON ss.ss_customer_sk = ce.c_customer_sk
  JOIN item_data it ON ss.ss_item_sk = it.i_item_sk
),
combined_sales AS (
  SELECT
    order_number,
    sold_date_sk,
    item_sk,
    quantity,
    sales_price,
    net_paid,
    net_profit,
    channel,
    d_date,
    d_year,
    d_month_seq,
    d_week_seq,
    d_day_name,
    email_domain,
    composite_key,
    composite_len,
    extra_string,
    string_prefix,
    bool_flag,
    code,
    tag
  FROM (
    SELECT
      ws_order_number AS order_number,
      ws_sold_date_sk AS sold_date_sk,
      ws_item_sk AS item_sk,
      ws_quantity AS quantity,
      ws_sales_price AS sales_price,
      ws_net_paid AS net_paid,
      ws_net_profit AS net_profit,
      'WEB' AS channel,
      d_date,
      d_year,
      d_month_seq,
      d_week_seq,
      d_day_name,
      email_domain,
      composite_key,
      composite_len,
      extra_string,
      string_prefix,
      bool_flag,
      code,
      tag
    FROM web_sales_enhanced

    UNION ALL

    SELECT
      ss_ticket_number AS order_number,
      ss_sold_date_sk AS sold_date_sk,
      ss_item_sk AS item_sk,
      ss_quantity AS quantity,
      ss_sales_price AS sales_price,
      ss_net_paid AS net_paid,
      ss_net_profit AS net_profit,
      'STORE' AS channel,
      d_date,
      d_year,
      d_month_seq,
      d_week_seq,
      d_day_name,
      email_domain,
      composite_key,
      composite_len,
      extra_string,
      string_prefix,
      bool_flag,
      code,
      tag
    FROM store_sales_enhanced
  )
),
domain_daily_rank AS (
  SELECT
    d_date,
    email_domain,
    COUNT(*) AS txn_count,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY COUNT(*) DESC) AS domain_rank
  FROM combined_sales
  GROUP BY d_date, email_domain
),
final_result AS (
  SELECT
    cs.d_date,
    cs.channel,
    cs.email_domain,
    cs.composite_key,
    cs.composite_len,
    cs.extra_string,
    cs.string_prefix,
    CASE WHEN cs.bool_flag THEN 'YES' ELSE 'NO' END AS has_feature,
    cs.code,
    cs.tag,
    dr.domain_rank,
    cs.net_profit,
    cs.net_paid,
    cs.sales_price,
    cs.quantity
  FROM combined_sales cs
  LEFT JOIN domain_daily_rank dr
    ON cs.d_date = dr.d_date AND cs.email_domain = dr.email_domain
  WHERE cs.composite_len > 20
    AND cs.sales_price > 0
    AND dr.domain_rank <= 5
)

SELECT
  d_date,
  channel,
  email_domain,
  domain_rank,
  COUNT(*) AS sales_transactions,
  SUM(quantity) AS total_quantity,
  SUM(net_paid) AS total_net_paid,
  SUM(net_profit) AS total_net_profit,
  AVG(composite_len) AS avg_composite_len,
  approx_distinct(composite_key) AS distinct_composite_keys,
  COUNT(DISTINCT extra_string) AS distinct_extra_strings,
  MAX(CASE WHEN has_feature = 'YES' THEN 1 ELSE 0 END) AS any_has_digit_in_desc,
  array_join(array_agg(DISTINCT tag ORDER BY tag), ',') AS tags
FROM final_result
GROUP BY d_date, channel, email_domain, domain_rank
