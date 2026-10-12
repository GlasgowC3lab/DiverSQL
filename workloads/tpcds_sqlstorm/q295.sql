WITH sales_strings AS (
  SELECT
    ws.ws_order_number AS order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    dd.d_date AS sale_date,
    i.i_product_name,
    i.i_item_desc,
    p.p_promo_name,
    wp.wp_url,
    w.w_warehouse_name,
    concat(
      lower(wp.wp_url), '::',
      upper(i.i_product_name), '::',
      regexp_replace(i.i_item_desc, '\\s+', ' '), '::',
      coalesce(p.p_promo_name, ''), '::',
      CAST(dd.d_date AS varchar), '::',
      replace(w.w_warehouse_name, ' ', '_')
    ) AS raw_concat,
    lower(regexp_replace(i.i_item_desc, '\\W+', '')) AS normalized_desc,
    length(concat(
      lower(wp.wp_url),
      upper(i.i_product_name),
      coalesce(p.p_promo_name, ''),
      CAST(dd.d_date AS varchar)
    )) AS str_len,
    cardinality(split(lower(wp.wp_url), '\\.')) AS url_token_count,
    array_join(split(i.i_item_desc, '\\s+'), '|') AS item_desc_tokenized,
    replace(replace(lower(wp.wp_url), 'http://', ''), 'https://', '') AS url_stripped,
    reverse(upper(w.w_warehouse_name)) AS rev_warehouse_name
  FROM web_sales ws
  JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE wp.wp_url IS NOT NULL
)
SELECT
  order_number,
  str_len,
  url_token_count,
  array_join(split(url_stripped, '\\.'), '|') AS url_domains,
  concat_ws('---', raw_concat, rev_warehouse_name, normalized_desc, item_desc_tokenized) AS final_complex_string,
  substr(concat_ws('---', raw_concat, rev_warehouse_name, normalized_desc, item_desc_tokenized), 1, 100) AS sample_prefix
FROM sales_strings
ORDER BY str_len DESC
LIMIT 100
