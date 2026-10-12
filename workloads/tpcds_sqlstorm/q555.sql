WITH combined_sales AS (
  SELECT
    c.c_customer_sk,
    c.c_email_address,
    lower(substr(c.c_email_address, strpos(c.c_email_address, '@') + 1)) AS email_domain,
    i.i_item_desc,
    i.i_product_name,
    i.i_color,
    i.i_size,
    i.i_container,
    cs.cs_net_paid AS cs_net,
    ws.ws_net_paid AS ws_net,
    ss.ss_net_paid AS ss_net,
    cc.cc_name AS call_center_name,
    cc.cc_manager AS call_center_manager,
    wp.wp_url,
    c.c_first_name,
    c.c_last_name
  FROM
    customer c
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN item i ON i.i_item_sk = COALESCE(ws.ws_item_sk, ss.ss_item_sk, cs.cs_item_sk)
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE
    c.c_email_address IS NOT NULL
    AND i.i_item_desc IS NOT NULL
)

SELECT
  email_domain,
  regexp_extract(email_domain, '\\.([^.]*)$', 1) AS top_level_domain,
  count(DISTINCT c_customer_sk) AS num_customers,
  sum(cs_net) AS total_catalog_net,
  sum(ws_net) AS total_web_net,
  sum(ss_net) AS total_store_net,
  avg(length(i_item_desc)) AS avg_item_desc_len,
  avg(length(regexp_replace(i_item_desc, '\\s+', ''))) AS avg_item_desc_len_no_spaces,
  avg(length(i_product_name)) AS avg_product_name_len,
  avg(cardinality(split(i_product_name, ' '))) AS avg_product_name_token_count,
  sum(CASE WHEN regexp_like(i_product_name, '[0-9]{4}') THEN 1 ELSE 0 END) AS products_with_4digit_seq,
  avg(length(call_center_name)) AS avg_call_center_name_len,
  sum(length(call_center_manager)) AS total_call_center_manager_name_len,
  arbitrary(regexp_extract(call_center_manager, '^([^ ]+)', 1)) AS call_center_manager_first_name,
  min(concat_ws(' ', lower(c_first_name), lower(c_last_name))) AS normalized_customer_name,
  arbitrary(regexp_replace(wp_url, '^https?://', '')) AS url_without_scheme,
  arbitrary(split(wp_url, '/')[1]) AS url_host_part,
  arbitrary(regexp_extract(wp_url, '^https?://([^/]+)/', 1)) AS url_host,
  arbitrary(array_join(split(i_product_name, ' '), '|')) AS product_name_tokens_piped,
  arbitrary(concat_ws(' - ', i_color, i_size, i_container)) AS product_spec_concat
FROM
  combined_sales
GROUP BY
  email_domain,
  regexp_extract(email_domain, '\\.([^.]*)$', 1)
ORDER BY
  total_web_net DESC
LIMIT 100
