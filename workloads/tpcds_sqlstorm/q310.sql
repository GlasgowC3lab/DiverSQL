WITH processed AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        wp.wp_web_page_id AS web_page_id,
        wp.wp_url AS url,
        regexp_extract(wp.wp_url, '^https?://([^/]+)/?.*$', 1) AS url_domain,
        regexp_replace(lower(regexp_extract(wp.wp_url, '^https?://([^/]+)/?.*$', 1)), '[^a-z0-9]', '') AS clean_domain,
        replace(lower(wp.wp_type), '-', '_') AS norm_page_type,
        regexp_extract(i.i_item_id, '\\d+', 0) AS item_id_num,
        regexp_replace(trim(i.i_product_name), '\\s+', '_') AS product_name_underscored,
        coalesce(p.p_promo_name, 'nopromo') AS promo_name_fallback,
        ws.ws_net_paid AS net_paid,
        ws.ws_quantity AS quantity
    FROM
        web_sales ws
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
        AND wp.wp_url IS NOT NULL
        AND i.i_product_name IS NOT NULL
)
SELECT
    order_number,
    sold_date_sk,
    item_id,
    product_name,
    promo_id,
    promo_name,
    web_page_id,
    url_domain,
    clean_domain,
    substr(clean_domain, 1, 5) AS domain_prefix,
    norm_page_type,
    item_id_num,
    product_name_underscored,
    concat_ws('|', clean_domain, norm_page_type, product_name_underscored, promo_name_fallback) AS signature,
    length(concat_ws('|', clean_domain, norm_page_type, product_name_underscored, promo_name_fallback)) AS signature_len,
    upper(concat_ws('|', clean_domain, norm_page_type, product_name_underscored, promo_name_fallback)) AS signature_upper,
    reverse(concat_ws('|', clean_domain, norm_page_type, product_name_underscored, promo_name_fallback)) AS signature_rev,
    length(regexp_replace(concat_ws('|', clean_domain, norm_page_type, product_name_underscored, promo_name_fallback), '[^aeiouAEIOU]', '')) AS vowel_count,
    cardinality(split(product_name, '\\s+')) AS product_name_word_count,
    sum(net_paid) OVER (PARTITION BY order_number) AS order_net_paid,
    avg(quantity) OVER (PARTITION BY order_number) AS avg_qty_per_order
FROM processed
ORDER BY sold_date_sk, order_number
LIMIT 100
