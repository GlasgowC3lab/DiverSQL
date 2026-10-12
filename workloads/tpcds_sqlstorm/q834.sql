WITH product_strings AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_color,
        i.i_size,
        i.i_units,
        i.i_manager_id,
        lower(i.i_brand) AS brand_lower,
        upper(i.i_color) AS color_upper,
        concat(i.i_brand, '-', i.i_color, '-', i.i_size) AS brand_color_size,
        regexp_replace(i.i_product_name, '\\s+', '_') AS prod_name_underscores,
        substr(i.i_product_name, 1, 5) AS prod_name_prefix,
        length(i.i_product_name) AS prod_name_len,
        strpos(i.i_product_name, ' ') AS first_space_pos,
        CASE WHEN regexp_like(i.i_product_name, '^[A-Z]') THEN 'CapStart' ELSE 'NonCap' END AS name_start_type,
        concat('MANAGER', lpad(cast(i.i_manager_id AS varchar), 5, '0')) AS manager_code
    FROM item i
),
joined_sales AS (
    SELECT
        ps.i_item_sk,
        ps.brand_color_size,
        ps.manager_code,
        cs.cs_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_year,
        ws.ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_web_page_sk
    FROM product_strings ps
    JOIN catalog_sales cs ON ps.i_item_sk = cs.cs_item_sk
    JOIN store_sales ss ON ps.i_item_sk = ss.ss_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ps.i_item_sk = ws.ws_item_sk AND cs.cs_sold_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_strings AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        replace(wp.wp_url, 'http://', '') AS url_no_http,
        split_part(replace(wp.wp_url, 'https://', ''), '/', 1) AS domain,
        regexp_extract(wp.wp_url, '://([^/]+)/', 1) AS domain_regex,
        lower(wp.wp_url) AS url_lower,
        regexp_replace(wp.wp_url, '[^a-zA-Z0-9]', '_') AS url_sanitized,
        length(wp.wp_url) AS url_length,
        strpos(wp.wp_url, '.com') AS com_pos
    FROM web_page wp
)
SELECT
    js.d_year,
    js.brand_color_size,
    count(*) AS total_sales,
    sum(js.ws_quantity) AS total_quantity,
    sum(js.ws_net_paid) AS total_net_paid,
    avg(js.ws_net_profit) AS avg_profit,
    min(ws.url_length) AS min_url_len,
    max(ws.url_length) AS max_url_len,
    approx_distinct(ws.domain) AS distinct_domains,
    array_join(array_agg(DISTINCT ws.url_sanitized), ',') AS sample_urls,
    sum(CASE WHEN ps.prod_name_len > 30 THEN 1 ELSE 0 END) AS long_name_count,
    sum(CASE WHEN ps.first_space_pos > 0 THEN 1 ELSE 0 END) AS names_with_spaces,
    sum(CASE WHEN ps.manager_code LIKE 'MANAGER0%' THEN 1 ELSE 0 END) AS manager_code_prefix_count
FROM joined_sales js
LEFT JOIN web_strings ws ON js.ws_web_page_sk = ws.wp_web_page_sk
LEFT JOIN product_strings ps ON js.i_item_sk = ps.i_item_sk
GROUP BY
    js.d_year,
    js.brand_color_size
ORDER BY
    total_net_paid DESC
LIMIT 100
