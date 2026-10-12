WITH sales_str AS (
    SELECT
        d.d_date,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_class,
        i.i_category,
        regexp_replace(lower(i.i_product_name), '\\s+', '-') AS product_slug,
        regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '') AS cleaned_desc,
        cardinality(split(i.i_item_desc, ' ')) AS desc_word_cnt,
        array_join(slice(split(i.i_item_desc, ' '), 1, 3), '|') AS first_three_words,
        lower(c.c_first_name) || '_' || lower(c.c_last_name) || '_' || substr(c.c_customer_id, 1, 4) AS cust_key,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        substr(upper(c.c_last_name), 1, 1) AS last_initial,
        format('%s-%s-%s', i.i_brand, i.i_class, i.i_category) AS product_label,
        concat_ws(' ', sm.sm_type, sm.sm_carrier) AS ship_mode_desc,
        substr(wp.wp_url, 1, 30) AS page_url_stub,
        concat(w.web_name, ' ', w.web_manager) AS site_info,
        ws.ws_net_paid,
        ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    CAST(s.d_date AS VARCHAR) AS sale_date,
    s.i_item_id,
    s.i_product_name,
    s.product_label,
    s.product_slug,
    s.cleaned_desc,
    s.desc_word_cnt,
    s.first_three_words,
    array_join(array_agg(DISTINCT s.cust_key), ',') AS cust_keys,
    array_join(array_agg(DISTINCT s.email_domain), ',') AS email_domains,
    array_agg(DISTINCT s.last_initial) AS last_initials,
    sum(s.ws_net_paid) AS total_net_paid,
    sum(s.ws_quantity) AS total_quantity,
    avg(s.ws_net_paid) AS avg_net_paid,
    count(*) AS sales_count,
    min(s.ws_net_paid) AS min_net_paid,
    max(s.ws_net_paid) AS max_net_paid,
    concat_ws(', ', array_agg(DISTINCT s.ship_mode_desc)) AS ship_modes,
    concat_ws(', ', array_agg(DISTINCT s.page_url_stub)) AS page_url_stubs,
    concat_ws(', ', array_agg(DISTINCT s.site_info)) AS site_infos
FROM sales_str s
GROUP BY
    s.d_date,
    s.i_item_id,
    s.i_product_name,
    s.product_label,
    s.product_slug,
    s.cleaned_desc,
    s.desc_word_cnt,
    s.first_three_words
