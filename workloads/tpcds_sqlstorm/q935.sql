SELECT
    cp.cp_catalog_page_id,
    c.c_customer_id,
    concat_ws(' - ', i.i_product_name, i.i_brand, i.i_color, i.i_size) AS product_full,
    lower(i.i_product_name) AS product_name_lower,
    upper(i.i_brand) AS brand_upper,
    regexp_replace(i.i_product_name, '[A-Za-z]{3}', '***') AS masked_name,
    translate(i.i_product_name, 'aeiou', 'AEIOU') AS vowel_caps,
    reverse(i.i_product_name) AS reversed_name,
    length(i.i_product_name) AS name_length,
    substr(i.i_item_desc, 1, 20) AS desc_prefix,
    array_join(array_agg(DISTINCT substr(i.i_item_desc, 1, 10)), ',') AS distinct_desc_snippets,
    sum(cs.cs_net_paid) AS total_net_paid,
    sum(cs.cs_quantity) AS total_quantity,
    count(DISTINCT cs.cs_order_number) AS distinct_orders
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE regexp_like(i.i_product_name, '^[A-Za-z]{5,}$')
  AND i.i_color IS NOT NULL
  AND i.i_size <> ''
  AND cp.cp_type = 'WEB'
GROUP BY cp.cp_catalog_page_id,
    c.c_customer_id,
    i.i_product_name,
    i.i_brand,
    i.i_color,
    i.i_size,
    i.i_item_desc
HAVING sum(cs.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
