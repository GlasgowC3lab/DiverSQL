WITH email_domains AS (
    SELECT
        c_customer_sk,
        c_email_address,
        regexp_extract(c_email_address, '@([^@]+)$', 1) AS domain,
        length(c_email_address) AS email_len,
        lower(c_email_address) AS email_lower,
        replace(c_email_address, '.', '') AS email_no_dots,
        cardinality(split(c_email_address, '@')) AS parts_cnt
    FROM customer
    WHERE c_email_address IS NOT NULL
),
customer_orders AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk AS cs_customer_sk,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        i.i_product_name,
        i.i_item_desc,
        lower(i.i_product_name) AS prod_name_lower,
        length(i.i_product_name) AS prod_name_len,
        cardinality(split(i.i_product_name, '\\s+')) AS prod_word_cnt,
        regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '') AS clean_desc,
        length(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS clean_desc_len,
        cp.cp_catalog_page_id,
        cp.cp_description,
        lower(cp.cp_description) AS cp_desc_lower,
        length(cp.cp_description) AS cp_desc_len,
        cc.cc_name,
        lower(cc.cc_name) AS cc_name_lower,
        length(cc.cc_name) AS cc_name_len,
        regexp_replace(cc.cc_hours, '\\s+', ' ') AS cc_hours_clean
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_net_paid > 0
),
aggregated AS (
    SELECT
        COALESCE(ed.domain, 'UNKNOWN') AS email_domain,
        COUNT(DISTINCT co.cs_customer_sk) AS distinct_customers,
        SUM(co.cs_net_paid) AS total_net_paid,
        AVG(co.cs_net_paid) AS avg_net_paid,
        SUM(co.cs_ext_sales_price) AS total_ext_sales,
        MIN(co.cs_sold_date_sk) AS first_sold_date_sk,
        MAX(co.cs_sold_date_sk) AS last_sold_date_sk,
        AVG(co.prod_name_len) AS avg_product_name_len,
        AVG(co.prod_word_cnt) AS avg_product_word_count,
        MAX(co.clean_desc_len) AS max_clean_desc_len,
        AVG(co.cc_name_len) AS avg_call_center_name_len,
        COUNT(*) AS total_rows,
        array_join(
            slice(array_agg(DISTINCT co.prod_name_lower ORDER BY co.prod_name_lower), 1, 5),
            ', '
        ) AS sample_product_names
    FROM customer_orders co
    LEFT JOIN email_domains ed ON co.cs_customer_sk = ed.c_customer_sk
    GROUP BY COALESCE(ed.domain, 'UNKNOWN')
)
SELECT
    email_domain,
    distinct_customers,
    total_net_paid,
    avg_net_paid,
    total_ext_sales,
    first_sold_date_sk,
    last_sold_date_sk,
    avg_product_name_len,
    avg_product_word_count,
    max_clean_desc_len,
    avg_call_center_name_len,
    total_rows,
    sample_product_names,
    REVERSE(email_domain) AS reversed_domain,
    LENGTH(email_domain) AS domain_len,
    UPPER(REVERSE(email_domain)) AS reversed_domain_upper
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
