WITH sales_str AS (
    SELECT
        d.d_year,
        lower(regexp_replace(cc.cc_name, '[^a-z0-9]', '-')) AS cc_name_norm,
        concat_ws('_', i.i_brand, i.i_color) AS brand_color_key,
        lower(regexp_extract(c.c_email_address, '@([A-Za-z0-9.-]+)', 1)) AS email_domain,
        lower(regexp_replace(c.c_email_address, '[^a-z0-9@.]', '')) AS email_norm,
        concat_ws(' ', c.c_first_name, c.c_last_name) AS cust_full_name,
        lower(regexp_replace(c.c_first_name, '[^a-z]', '')) AS first_name_alpha,
        length(c.c_email_address) AS email_len,
        regexp_extract(i.i_item_id, '\\d+', 0) AS item_number_str,
        cast(regexp_extract(i.i_item_id, '\\d+', 0) as integer) AS item_number,
        reverse(i.i_item_id) AS rev_item_id,
        lower(regexp_replace(i.i_product_name, '[^a-z0-9 ]', '')) AS product_name_clean,
        substr(i.i_product_name, 1, 15) AS product_name_prefix,
        split_part(i.i_product_name, ' ', 1) AS product_first_word,
        array_join(
            array_sort(
                array_distinct(
                    split(cp.cp_description, ' ')
                )
            ),
            '|'
        ) AS cp_desc_distinct_sorted,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        repeat('x', cs.cs_quantity) AS quantity_x_str,
        length(cp.cp_description) AS cp_desc_len,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        concat_ws(', ', ca.ca_city, ca.ca_state, ca.ca_zip) AS city_state_zip,
        regexp_replace(concat_ws(' ', ca.ca_city, ca.ca_state, ca.ca_zip), '[^a-z0-9]', '') AS city_state_zip_norm
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND c.c_email_address IS NOT NULL
      AND i.i_product_name IS NOT NULL
)
SELECT
    s.d_year,
    s.cc_name_norm,
    s.brand_color_key,
    s.email_domain,
    count(*) AS sales_cnt,
    sum(s.net_profit) AS total_net_profit,
    avg(s.net_profit) AS avg_net_profit,
    sum(s.quantity) AS total_quantity,
    avg(s.quantity) AS avg_quantity,
    approx_distinct(s.item_number) AS distinct_items,
    array_join(array_sort(array_agg(DISTINCT s.product_first_word)), '|') AS distinct_product_first_words,
    max(s.email_len) AS max_email_len,
    min(s.email_len) AS min_email_len,
    approx_percentile(s.email_len, 0.5) AS median_email_len,
    sum(coalesce(length(s.city_state_zip_norm), 0)) AS total_city_state_zip_norm_len
FROM sales_str s
GROUP BY
    s.d_year,
    s.cc_name_norm,
    s.brand_color_key,
    s.email_domain
ORDER BY
    s.d_year,
    total_net_profit DESC
