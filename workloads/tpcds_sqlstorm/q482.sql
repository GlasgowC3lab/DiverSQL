WITH
item_norm AS (
    SELECT
        i.i_item_sk,
        lower(regexp_replace(concat_ws('_', i.i_brand, i.i_class, i.i_category, i.i_color, i.i_size, i.i_product_name), '[^a-z0-9_]', '')) AS norm_item_key,
        length(i.i_item_desc) AS desc_len,
        cardinality(split(i.i_item_desc, '\\s+')) AS desc_word_cnt
    FROM item i
),
call_center_norm AS (
    SELECT
        cc.cc_call_center_sk,
        lower(regexp_replace(cc.cc_manager, '\\s+', '_')) AS norm_manager,
        length(cc.cc_name) AS cc_name_len
    FROM call_center cc
),
promo_norm AS (
    SELECT
        p.p_promo_sk,
        lower(regexp_replace(p.p_promo_name, '\\s+', '_')) AS norm_promo_name,
        length(p.p_promo_name) AS promo_name_len
    FROM promotion p
),
customer_norm AS (
    SELECT
        c.c_customer_sk,
        lower(trim(concat_ws(' ', c.c_first_name, c.c_last_name))) AS norm_customer_name,
        lower(regexp_replace(c.c_email_address, '[^a-z0-9@.]', '')) AS norm_email,
        length(c.c_email_address) AS email_len
    FROM customer c
),
address_norm AS (
    SELECT
        ca.ca_address_sk,
        lower(regexp_replace(concat_ws(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number, ca.ca_city, ca.ca_state, ca.ca_zip, ca.ca_country), '[^a-z0-9 ]', '')) AS norm_address,
        length(ca.ca_city) + length(ca.ca_state) AS city_state_len
    FROM customer_address ca
),
web_page_norm AS (
    SELECT
        wp.wp_web_page_sk,
        lower(regexp_extract(wp.wp_url, '(?i)^(?:https?://)?([^/]+)', 1)) AS norm_domain,
        lower(regexp_replace(wp.wp_url, '[^a-z0-9]', '_')) AS norm_url,
        length(regexp_extract(wp.wp_url, '(?i)^(?:https?://)?([^/]+)', 1)) AS domain_len
    FROM web_page wp
),
catalog_sales_processed AS (
    SELECT
        concat_ws('||',
            i.norm_item_key,
            cc.norm_manager,
            p.norm_promo_name,
            c.norm_customer_name,
            a.norm_address
        ) AS heavy_string,
        cs.cs_net_paid_inc_tax AS net_paid,
        cs.cs_quantity AS quantity,
        cs.cs_ext_discount_amt AS discount,
        i.desc_len,
        i.desc_word_cnt,
        cc.cc_name_len AS extra_len_1,
        p.promo_name_len AS extra_len_2,
        c.email_len,
        a.city_state_len AS extra_len_3
    FROM catalog_sales cs
    JOIN item_norm i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center_norm cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promo_norm p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN customer_norm c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN address_norm a ON cs.cs_bill_addr_sk = a.ca_address_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
store_sales_processed AS (
    SELECT
        concat_ws('||',
            i.norm_item_key,
            s.s_store_name,
            p.norm_promo_name,
            c.norm_customer_name,
            a.norm_address
        ) AS heavy_string,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount,
        i.desc_len,
        i.desc_word_cnt,
        length(s.s_store_name) AS extra_len_1,
        p.promo_name_len AS extra_len_2,
        c.email_len,
        a.city_state_len AS extra_len_3
    FROM store_sales ss
    JOIN item_norm i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promo_norm p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_norm c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN address_norm a ON ss.ss_addr_sk = a.ca_address_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_sales_processed AS (
    SELECT
        concat_ws('||',
            i.norm_item_key,
            wp.norm_domain,
            p.norm_promo_name,
            c.norm_customer_name,
            a.norm_address
        ) AS heavy_string,
        ws.ws_net_paid_inc_tax AS net_paid,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount,
        i.desc_len,
        i.desc_word_cnt,
        wp.domain_len AS extra_len_1,
        p.promo_name_len AS extra_len_2,
        c.email_len,
        a.city_state_len AS extra_len_3
    FROM web_sales ws
    JOIN item_norm i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page_norm wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promo_norm p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN customer_norm c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN address_norm a ON ws.ws_bill_addr_sk = a.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    heavy_string,
    sum(net_paid) AS total_net_paid,
    sum(quantity) AS total_quantity,
    avg(discount) AS avg_discount,
    sum(desc_len) AS sum_desc_len,
    sum(desc_word_cnt) AS sum_desc_word_cnt,
    avg(email_len) AS avg_email_len,
    sum(extra_len_1) AS sum_extra_len_1,
    sum(extra_len_2) AS sum_extra_len_2,
    sum(extra_len_3) AS sum_extra_len_3,
    count(*) AS rows_processed
FROM (
    SELECT * FROM catalog_sales_processed
    UNION ALL
    SELECT * FROM store_sales_processed
    UNION ALL
    SELECT * FROM web_sales_processed
) u
GROUP BY heavy_string
ORDER BY total_net_paid DESC
LIMIT 100
