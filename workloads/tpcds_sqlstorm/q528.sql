WITH cleaned_customers AS (
 SELECT c_customer_sk,
        lower(regexp_replace(c_email_address, '[^a-z0-9@.]', '')) AS clean_email,
        concat(upper(substr(c_first_name,1,1)), upper(substr(c_last_name,1,1))) AS initials,
        length(c_first_name) + length(c_last_name) AS name_len
 FROM customer
),
product_features AS (
 SELECT i_item_sk,
        lower(regexp_replace(i_product_name, '\\s+', '')) AS clean_product_name,
        regexp_extract(i_item_desc, '(\\w+)', 1) AS first_word_desc,
        cardinality(split(i_item_desc, ' ')) AS word_count_desc,
        length(i_product_name) AS prod_name_len,
        case when regexp_like(i_product_name, '^.{5}$') then true else false end AS is_five_char_name,
        reverse(i_product_name) AS reversed_name
 FROM item
),
call_center_features AS (
 SELECT cc_call_center_sk,
        lower(regexp_replace(cc_name, '\\s+', '')) AS clean_cc_name,
        regexp_extract(cc_hours, '(\\d{2}:\\d{2})', 1) AS open_time,
        length(cc_manager) AS manager_name_len
 FROM call_center
),
store_features AS (
 SELECT s_store_sk,
        lower(regexp_replace(s_store_name, '\\s+', '')) AS clean_store_name,
        substr(s_store_name, 1, 3) AS store_prefix,
        length(s_city) AS city_name_len
 FROM store
),
web_page_features AS (
 SELECT wp_web_page_sk,
        lower(regexp_replace(wp_url, 'https?://', '')) AS clean_url,
        regexp_extract(wp_url, '([^/]+)', 1) AS domain,
        length(wp_type) AS page_type_len
 FROM web_page
),
sales_store AS (
 SELECT 
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS integer) AS call_center_sk,
        CAST(NULL AS integer) AS web_page_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS sales_channel,
        lower(regexp_replace(CAST(ss.ss_quantity AS varchar), '\\d+', '')) AS qty_str_processed,
        length(CAST(ss.ss_quantity AS varchar)) AS qty_len
 FROM store_sales ss
),
sales_web AS (
 SELECT 
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        CAST(NULL AS integer) AS store_sk,
        CAST(NULL AS integer) AS call_center_sk,
        ws.ws_web_page_sk AS web_page_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'web' AS sales_channel,
        lower(regexp_replace(CAST(ws.ws_quantity AS varchar), '\\d+', '')) AS qty_str_processed,
        length(CAST(ws.ws_quantity AS varchar)) AS qty_len
 FROM web_sales ws
),
sales_catalog AS (
 SELECT 
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        CAST(NULL AS integer) AS store_sk,
        cs.cs_call_center_sk AS call_center_sk,
        CAST(NULL AS integer) AS web_page_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'catalog' AS sales_channel,
        lower(regexp_replace(CAST(cs.cs_quantity AS varchar), '\\d+', '')) AS qty_str_processed,
        length(CAST(cs.cs_quantity AS varchar)) AS qty_len
 FROM catalog_sales cs
),
combined_sales AS (
 SELECT * FROM sales_store
 UNION ALL
 SELECT * FROM sales_web
 UNION ALL
 SELECT * FROM sales_catalog
),
aggregated AS (
 SELECT 
        cs.sales_channel,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        pf.clean_product_name,
        pf.first_word_desc,
        pf.word_count_desc,
        pf.prod_name_len,
        pf.is_five_char_name,
        cc.clean_cc_name,
        st.clean_store_name,
        wp.clean_url,
        cu.clean_email,
        cu.initials,
        cu.name_len,
        cs.qty_str_processed,
        cs.qty_len,
        sum(cs.net_paid) AS total_net_paid,
        sum(cs.net_profit) AS total_net_profit,
        count(*) AS sales_cnt,
        approx_distinct(cs.customer_sk) AS distinct_customers
 FROM combined_sales cs
 LEFT JOIN date_dim d ON cs.sold_date_sk = d.d_date_sk
 LEFT JOIN product_features pf ON cs.item_sk = pf.i_item_sk
 LEFT JOIN cleaned_customers cu ON cs.customer_sk = cu.c_customer_sk
 LEFT JOIN store_features st ON cs.sales_channel = 'store' AND cs.store_sk = st.s_store_sk
 LEFT JOIN call_center_features cc ON cs.sales_channel = 'catalog' AND cs.call_center_sk = cc.cc_call_center_sk
 LEFT JOIN web_page_features wp ON cs.sales_channel = 'web' AND cs.web_page_sk = wp.wp_web_page_sk
 GROUP BY 
        cs.sales_channel,
        d.d_year,
        d.d_month_seq,
        pf.clean_product_name,
        pf.first_word_desc,
        pf.word_count_desc,
        pf.prod_name_len,
        pf.is_five_char_name,
        cc.clean_cc_name,
        st.clean_store_name,
        wp.clean_url,
        cu.clean_email,
        cu.initials,
        cu.name_len,
        cs.qty_str_processed,
        cs.qty_len
)
SELECT *
FROM aggregated
ORDER BY sales_channel, year, month_seq
LIMIT 100
