SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    i.i_category,
    p.p_promo_name,
    CONCAT_WS('||', s.s_store_name, c.c_last_name, i.i_brand) AS store_cust_brand_key,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    LOWER(c.c_email_address) AS email_lower,
    SUBSTR(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain,
    LENGTH(c.c_email_address) AS email_len,
    UPPER(ca.ca_city) AS city_upper,
    LOWER(ca.ca_state) AS state_lower,
    CONCAT(s.s_store_name, '-', ca.ca_city) AS store_city_key,
    TRIM(i.i_item_desc) AS item_desc_trim,
    REPLACE(i.i_item_desc, '-', ' ') AS item_desc_spaces,
    REGEXP_REPLACE(i.i_item_desc, '\\s+', ' ') AS item_desc_normalized,
    LENGTH(REGEXP_REPLACE(i.i_item_desc, '\\s+', ' ')) AS item_desc_norm_len,
    SUBSTR(i.i_product_name, 1, 10) AS product_name_prefix,
    REVERSE(i.i_product_name) AS product_name_rev,
    UPPER(p.p_channel_email) AS channel_email_upper,
    TRANSLATE(p.p_channel_email, 'aeiou', '12345') AS channel_email_encoded,
    SUBSTR(p.p_promo_name, 1, 5) || '_' || SUBSTR(p.p_promo_name, LENGTH(p.p_promo_name) - 4, 5) AS promo_name_boundary,
    COALESCE(NULLIF(TRIM(s.s_hours), ''), 'UNKNOWN') AS store_hours_clean,
    CASE WHEN strpos(lower(i.i_item_desc), 'steel') > 0 THEN 1 ELSE 0 END AS has_steel_flag,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_quantity) AS avg_qty,
    MIN(ss.ss_sold_date_sk) AS min_sold_date_sk,
    MAX(CAST(ss.ss_sold_date_sk AS varchar)) AS max_sold_date_sk_str,
    CONCAT(
        SUBSTR(s.s_store_name, 1, 3),
        '-',
        SUBSTR(c.c_last_name, LENGTH(c.c_last_name) - 1, 2),
        '-',
        LPAD(CAST(d.d_month_seq AS varchar), 2, '0')
    ) AS composite_key,
    LENGTH(CONCAT(
        SUBSTR(s.s_store_name, 1, 3),
        '-',
        SUBSTR(c.c_last_name, LENGTH(c.c_last_name) - 1, 2),
        '-',
        LPAD(CAST(d.d_month_seq AS varchar), 2, '0')
    )) AS composite_key_len,
    array_join(array_agg(DISTINCT i.i_color), ',') AS colors_sold,
    REGEXP_EXTRACT(p.p_promo_name, '(.*)\\s+\\d+', 1) AS promo_name_text
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year BETWEEN 1998 AND 2002
  AND s.s_state IN ('CA', 'TX', 'NY')
  AND i.i_color IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    i.i_category,
    p.p_promo_name,
    i.i_brand,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    ca.ca_city,
    ca.ca_state,
    i.i_item_desc,
    i.i_product_name,
    p.p_channel_email,
    s.s_hours
HAVING COUNT(*) > 10
ORDER BY total_net_paid DESC
LIMIT 100
