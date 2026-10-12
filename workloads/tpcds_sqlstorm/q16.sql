WITH sales AS (
    SELECT
        d.d_date AS sale_date,
        'catalog' AS sales_source,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        i.i_product_name AS product_name,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.c_email_address AS email_address,
        cs.cs_net_paid AS net_paid,
        cc.cc_name AS extra_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001

    UNION ALL

    SELECT
        d.d_date AS sale_date,
        'store' AS sales_source,
        ss.ss_ticket_number AS order_number,
        ss.ss_quantity AS quantity,
        i.i_product_name AS product_name,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.c_email_address AS email_address,
        ss.ss_net_paid AS net_paid,
        s.s_store_name AS extra_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001

    UNION ALL

    SELECT
        d.d_date AS sale_date,
        'web' AS sales_source,
        ws.ws_order_number AS order_number,
        ws.ws_quantity AS quantity,
        i.i_product_name AS product_name,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.c_email_address AS email_address,
        ws.ws_net_paid AS net_paid,
        wp.wp_url AS extra_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
)

SELECT
    sale_date,
    sales_source,
    order_number,
    concat_ws(' ', CAST(quantity AS VARCHAR), 'units of', product_name) AS order_desc,
    concat(lower(trim(first_name)), '_', lower(trim(last_name))) AS cust_key,
    length(concat(lower(trim(first_name)), '_', lower(trim(last_name)))) AS cust_key_len,
    split_part(email_address, '@', 1) AS email_user,
    split_part(email_address, '@', 2) AS email_domain,
    substr(product_name, 1, 30) AS product_name_prefix,
    replace(product_name, '-', ' ') AS product_name_no_dash,
    regexp_replace(product_name, '[^A-Za-z0-9 ]', '') AS product_name_alphanum,
    length(regexp_replace(product_name, '[^A-Za-z0-9 ]', '')) AS product_name_alphanum_len,
    reverse(product_name) AS product_name_rev,
    strpos(lower(product_name), 'e') AS first_e_pos,
    CASE WHEN lower(product_name) LIKE '%green%' THEN 'GreenProduct' ELSE 'Other' END AS prod_color_cat,
    lower(coalesce(extra_name, '')) AS extra_name_lower,
    length(coalesce(extra_name, '')) AS extra_name_len,
    replace(coalesce(extra_name, ''), ' ', '') AS extra_name_nospaces,
    substr(coalesce(extra_name, ''), 1, 5) AS extra_prefix,
    reverse(coalesce(extra_name, '')) AS extra_name_rev,
    concat('Extra:', coalesce(extra_name, '')) AS extra_name_formatted,
    format('$%.2f', net_paid) AS net_paid_formatted,
    format('%09d', order_number) AS order_number_padded,
    substr(format('%09d', order_number), -4) AS order_number_last4,
    concat_ws('-', CAST(sale_date AS VARCHAR), CAST(order_number AS VARCHAR)) AS composite_key,
    length(concat_ws('-', CAST(sale_date AS VARCHAR), CAST(order_number AS VARCHAR))) AS composite_key_len
FROM sales
ORDER BY sale_date, sales_source, order_number
LIMIT 100
