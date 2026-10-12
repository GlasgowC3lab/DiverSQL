WITH sales_strings AS (
    SELECT
        ws.ws_order_number,
        i.i_item_id,
        i.i_product_name,
        reverse(i.i_product_name) AS product_name_rev,
        lower(regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '')) AS clean_product_name,
        length(i.i_product_name) AS product_name_len,
        cardinality(regexp_split(i.i_product_name, '\\s+')) AS product_word_cnt,
        c.c_customer_id,
        lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS customer_full_name,
        concat_ws('_',
            substr(lower(c.c_first_name), 1, 1),
            substr(lower(c.c_last_name), 1, 1),
            CAST(d.d_year AS varchar)
        ) AS cust_year_code,
        wp.wp_url,
        regexp_replace(wp.wp_url, '^https?://', '') AS url_no_protocol,
        replace(regexp_replace(wp.wp_url, '[^a-zA-Z0-9/]', ''), '/', '_') AS url_sanitized,
        ws.ws_quantity,
        ws.ws_net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_product_name IS NOT NULL
)
SELECT
    i_item_id,
    clean_product_name,
    product_name_len,
    product_word_cnt,
    max(product_name_rev) AS reversed_product_name,
    count(DISTINCT c_customer_id) AS distinct_customers,
    sum(ws_quantity) AS total_quantity,
    sum(ws_net_paid) AS total_net_paid,
    array_join(array_distinct(array_agg(url_no_protocol)), ', ') AS uniq_urls,
    array_join(array_distinct(array_agg(url_sanitized)), ', ') AS uniq_sanitized_urls,
    min(cust_year_code) AS sample_cust_year_code,
    count(*) AS total_rows
FROM sales_strings
GROUP BY
    i_item_id,
    clean_product_name,
    product_name_len,
    product_word_cnt
HAVING sum(ws_quantity) > 10
ORDER BY total_net_paid DESC
LIMIT 50
