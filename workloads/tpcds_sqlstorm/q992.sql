WITH base AS (
  SELECT
    date_trunc('month', d.d_date) AS month_date,
    cc.cc_name,
    c.c_last_name,
    c.c_email_address,
    c.c_login,
    i.i_product_name,
    i.i_item_desc,
    i.i_brand,
    i.i_color,
    i.i_size,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    p.p_promo_name,
    p.p_cost,
    p.p_channel_email,
    p.p_channel_tv,
    cp.cp_description
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year = 2002
),
processed AS (
  SELECT
    month_date,
    lower(i_product_name) AS prod_name_lc,
    regexp_replace(i_brand, '\\s+', '_') AS brand_norm,
    regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', '') AS desc_clean,
    cardinality(split(regexp_replace(i_item_desc, '[^A-Za-z0-9 ]', ''), ' ')) AS desc_word_cnt,
    replace(c_email_address, '@', '_AT_') AS email_masked,
    reverse(c_login) AS login_rev,
    concat(substr(cc_name, 1, 4), '-', substr(c_last_name, length(c_last_name) - 2, 3)) AS short_code,
    concat_ws('_', lower(p_promo_name), p_channel_email, p_channel_tv) AS promo_key,
    concat_ws('|', lower(i_product_name), regexp_replace(i_brand, '\\s+', '_'), substr(i_item_desc, 1, 10)) AS composite_key,
    strpos(lower(i_item_desc), 'special') AS special_pos,
    length(lower(i_product_name)) AS prod_name_lc_len,
    cs_quantity,
    cs_net_paid,
    cs_net_profit,
    CAST(p_cost AS varchar) AS promo_cost_str,
    substr(cp_description, 1, 20) AS cp_desc_prefix
  FROM base
),
aggregated AS (
  SELECT
    month_date,
    short_code,
    count(*) AS txn_cnt,
    sum(cs_net_paid) AS total_paid,
    sum(cs_net_profit) AS total_profit,
    avg(prod_name_lc_len) AS avg_prod_name_len,
    max(desc_word_cnt) AS max_desc_word_cnt,
    sum(CASE WHEN special_pos > 0 THEN 1 ELSE 0 END) AS special_desc_cnt,
    approx_distinct(composite_key) AS distinct_keys,
    approx_percentile(cs_net_paid, 0.5) AS median_paid
  FROM processed
  GROUP BY month_date, short_code
)
SELECT
  month_date,
  short_code,
  txn_cnt,
  total_paid,
  total_profit,
  avg_prod_name_len,
  max_desc_word_cnt,
  special_desc_cnt,
  distinct_keys,
  median_paid,
  row_number() OVER (PARTITION BY month_date ORDER BY total_paid DESC) AS month_rank
FROM aggregated
ORDER BY month_date, month_rank
LIMIT 200
