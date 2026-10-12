WITH ws_str AS (
    SELECT
        d.d_year,
        i.i_product_name,
        i.i_color,
        i.i_size,
        i.i_brand,
        concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand) AS product_full_name,
        lower(regexp_replace(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand), '[^a-z0-9 ]', '')) AS normalized_product_full_name,
        length(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand)) AS product_full_name_len,
        cardinality(split(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand), ' ')) AS product_word_count,
        CASE WHEN regexp_like(concat_ws(' ', i.i_product_name, i.i_color, i.i_size, i.i_brand), '[0-9]') THEN 'HasDigits' ELSE 'NoDigits' END AS product_digit_flag,
        split_part(wp.wp_url, '/', 3) AS url_domain,
        lower(split_part(wp.wp_url, '/', 3)) AS url_domain_lower,
        lower(wp.wp_url) LIKE 'https://%' AS is_https_url,
        trim(concat_ws(', ', we.web_city, we.web_state, we.web_country)) AS site_location,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wp.wp_url IS NOT NULL
      AND i.i_product_name IS NOT NULL
)
SELECT
    d_year,
    product_digit_flag,
    url_domain_lower,
    sum(ws_net_paid) AS total_net_paid,
    avg(ws_net_paid) AS avg_net_paid,
    sum(ws_quantity) AS total_quantity,
    sum(product_full_name_len) AS total_name_length,
    count(DISTINCT normalized_product_full_name) AS distinct_normalized_names,
    sum(product_word_count) AS total_word_count,
    sum(CASE WHEN is_https_url THEN 1 ELSE 0 END) AS https_url_count,
    avg(length(site_location)) AS avg_site_location_len,
    count(*) AS row_count
FROM ws_str
GROUP BY d_year, product_digit_flag, url_domain_lower
ORDER BY d_year, product_digit_flag, url_domain_lower
