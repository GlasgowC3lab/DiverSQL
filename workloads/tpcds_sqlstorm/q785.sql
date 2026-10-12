WITH enriched AS (
  SELECT
    lower(regexp_replace(i.i_item_desc, '[^a-z0-9]', ' ')) AS normalized_item_desc,
    cardinality(split(i.i_item_desc, '\\s+')) AS item_desc_word_count,
    substring(i.i_product_name, 1, 3) || '-' || substring(i.i_product_name, greatest(length(i.i_product_name) - 2, 1), 3) AS product_name_abbr,
    replace(cc.cc_call_center_id, '-', '') AS call_center_id_clean,
    concat_ws(', ', cc.cc_city, cc.cc_state) AS call_center_location,
    lower(trim(p.p_promo_name)) AS promo_name_clean,
    concat_ws('|',
        p.p_channel_dmail,
        p.p_channel_email,
        p.p_channel_catalog,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press,
        p.p_channel_event,
        p.p_channel_demo) AS promo_channels,
    lower(regexp_replace(cp.cp_description, '\\s+', ' ')) AS catalog_page_desc_clean,
    concat_ws(' ', trim(c.c_first_name), trim(c.c_last_name)) AS customer_full_name,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    reverse(regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_domain_rev,
    cs.cs_net_paid,
    cs.cs_net_profit
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE lower(i.i_item_desc) LIKE '%gift%'
    AND p.p_discount_active = 'Y'
    AND d.d_year = 2002
)
SELECT
  normalized_item_desc,
  item_desc_word_count,
  product_name_abbr,
  call_center_id_clean,
  call_center_location,
  promo_name_clean,
  promo_channels,
  catalog_page_desc_clean,
  customer_full_name,
  email_domain,
  email_domain_rev,
  sum(cs_net_paid) AS total_net_paid,
  avg(cs_net_profit) AS avg_net_profit,
  count(*) AS sales_rows
FROM enriched
GROUP BY
  normalized_item_desc,
  item_desc_word_count,
  product_name_abbr,
  call_center_id_clean,
  call_center_location,
  promo_name_clean,
  promo_channels,
  catalog_page_desc_clean,
  customer_full_name,
  email_domain,
  email_domain_rev
ORDER BY total_net_paid DESC
LIMIT 50
