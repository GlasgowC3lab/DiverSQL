WITH processed AS (
 SELECT
    cs.cs_order_number,
    c.c_customer_id,
    lower(c.c_first_name) || '_' || lower(c.c_last_name) || '-' || substr(ca.ca_city, 1, 5) || '-' || regexp_replace(i.i_item_desc, '\\s+', '_') AS customer_item_key,
    length(ca.ca_city) AS city_len,
    position('a' IN lower(c.c_last_name)) AS pos_a_last_name,
    split_part(c.c_email_address, '@', 2) AS email_domain,
    CASE WHEN regexp_like(c.c_email_address, '^.*@example\\.com$') THEN 1 ELSE 0 END AS is_example_email,
    replace(cp.cp_type, ' ', '-') AS cp_type_norm,
    regexp_replace(cc.cc_name, '[^A-Za-z0-9]', '') AS cc_name_clean,
    format('%s-%s', ws.ws_web_page_sk, ws.ws_order_number) AS web_order_key,
    reverse(substr(i.i_product_name, 1, 10)) AS rev_product_name,
    cs.cs_net_paid,
    cs.cs_quantity,
    cardinality(regexp_split(i.i_item_desc, '\\s+')) AS item_desc_word_count,
    trim(cp.cp_description) AS cp_desc_trim,
    lower(cp.cp_department) AS cp_department_lc,
    replace(cc.cc_hours, ':', '-') AS cc_hours_norm,
    length(regexp_replace(i.i_product_name, '[^A-Za-z]', '')) AS product_name_alpha_len,
    concat_ws('#', c.c_customer_id, ca.ca_address_id, cc.cc_call_center_id) AS composite_id
 FROM
    catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
 WHERE
    cs.cs_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2001)
    AND regexp_like(cp.cp_description, '(?i)(sale|discount)')
    AND position('e' IN lower(cp.cp_department)) > 0
)
SELECT
    customer_item_key,
    count(*) AS order_cnt,
    sum(cs_net_paid) AS total_net_paid,
    avg(cs_quantity) AS avg_quantity,
    max(city_len) AS max_city_length,
    min(pos_a_last_name) AS min_a_position_last_name,
    count(DISTINCT email_domain) AS distinct_email_domains,
    sum(is_example_email) AS example_email_orders,
    avg(length(cp_type_norm)) AS avg_cp_type_len,
    max(length(cc_name_clean)) AS max_cc_name_clean_len,
    min(length(rev_product_name)) AS min_rev_product_name_len,
    sum(item_desc_word_count) AS total_item_desc_words,
    avg(length(cp_desc_trim)) AS avg_cp_desc_len,
    avg(length(cp_department_lc)) AS avg_cp_department_len,
    avg(length(cc_hours_norm)) AS avg_cc_hours_len,
    avg(product_name_alpha_len) AS avg_product_name_alpha_len,
    count(DISTINCT composite_id) AS distinct_composite_ids
FROM
    processed
GROUP BY
    customer_item_key
ORDER BY
    total_net_paid DESC
LIMIT 10
