SELECT
    d.d_year,
    i.i_item_id,
    lower(regexp_replace(word, '[^a-z0-9]', '')) AS normalized_word,
    sum(cs.cs_quantity) AS total_quantity,
    sum(cs.cs_net_paid) AS total_net_paid,
    count(DISTINCT cs.cs_order_number) AS distinct_orders,
    max(length(i.i_product_name)) AS max_product_name_len,
    max(length(cc.cc_name)) AS max_call_center_name_len,
    concat_ws(' - ', cc.cc_name, i.i_product_name) AS cc_product_concat,
    array_agg(DISTINCT substr(cp.cp_description, 1, 30)) AS sample_page_desc,
    replace(cc.cc_manager, ' ', '') AS manager_no_spaces,
    length(replace(cc.cc_manager, ' ', '')) AS manager_no_spaces_len
FROM
    catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
WHERE
    d.d_year BETWEEN 1998 AND 2002
    AND i.i_item_desc IS NOT NULL
    AND cc.cc_name IS NOT NULL
GROUP BY
    d.d_year,
    i.i_item_id,
    lower(regexp_replace(word, '[^a-z0-9]', '')),
    cc.cc_name,
    i.i_product_name,
    cc.cc_manager
HAVING
    sum(cs.cs_quantity) > 10
ORDER BY
    total_quantity DESC
LIMIT 100
