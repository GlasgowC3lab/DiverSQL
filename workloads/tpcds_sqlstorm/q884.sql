WITH item_processed AS (
    SELECT
        i_item_sk,
        i_product_name,
        lower(i_product_name) AS product_name_lc,
        replace(i_product_name, ' ', '-') AS product_name_hyphen,
        regexp_replace(i_product_name, '\\s+', '_') AS product_name_underscored,
        substr(i_product_name, 1, 5) AS product_name_prefix,
        length(i_product_name) AS product_name_len,
        reverse(i_product_name) AS product_name_rev,
        CASE WHEN i_product_name = reverse(i_product_name) THEN 1 ELSE 0 END AS is_palindrome,
        regexp_extract(i_product_name, '(\\d+)', 1) AS numeric_part,
        cardinality(split(i_product_name, '\\s+')) AS word_count
    FROM item
),
sales AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_store_sk AS store_sk,
        NULL AS web_page_sk,
        ss_item_sk AS item_sk,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk AS sold_date_sk,
        NULL AS store_sk,
        ws_web_page_sk AS web_page_sk,
        ws_item_sk AS item_sk,
        ws_net_paid AS net_paid,
        ws_net_profit AS net_profit,
        ws_quantity AS quantity
    FROM web_sales
),
sales_enriched AS (
    SELECT
        s.sold_date_sk,
        s.store_sk,
        s.web_page_sk,
        s.item_sk,
        s.net_paid,
        s.net_profit,
        s.quantity,
        d.d_year,
        d.d_month_seq,
        ip.product_name_lc,
        ip.product_name_hyphen,
        ip.product_name_underscored,
        ip.product_name_prefix,
        ip.product_name_len,
        ip.is_palindrome,
        ip.numeric_part,
        ip.word_count,
        wp.wp_url,
        lower(wp.wp_url) AS url_lc,
        length(wp.wp_url) AS url_len,
        regexp_extract(wp.wp_url, '://([^/]+)/', 1) AS url_domain
    FROM sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item_processed ip ON s.item_sk = ip.i_item_sk
    LEFT JOIN web_page wp ON s.web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
)
SELECT
    d_year,
    d_month_seq,
    store_sk,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    AVG(product_name_len) AS avg_product_name_len,
    SUM(is_palindrome) AS palindrome_name_count,
    COUNT(DISTINCT numeric_part) AS distinct_numeric_parts,
    AVG(word_count) AS avg_word_count,
    MAX(product_name_len) AS max_product_name_len,
    MIN(product_name_len) AS min_product_name_len,
    COUNT(*) FILTER (WHERE product_name_lc LIKE '%red%') AS red_product_cnt,
    COUNT(*) FILTER (WHERE product_name_underscored LIKE '%_inc%') AS inc_product_cnt,
    AVG(url_len) AS avg_url_len,
    COUNT(DISTINCT url_domain) AS distinct_url_domains,
    COUNT(*) FILTER (WHERE url_lc LIKE '%example.com%') AS example_com_url_cnt
FROM sales_enriched
GROUP BY d_year, d_month_seq, store_sk
ORDER BY d_year, d_month_seq, total_net_profit DESC
LIMIT 100
