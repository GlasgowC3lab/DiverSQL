WITH sales AS (
  SELECT
    ws.ws_order_number AS ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_net_paid AS ws_net_paid,
    ws.ws_sold_date_sk,
    ws.ws_promo_sk,
    ws.ws_web_page_sk,
    ws.ws_web_site_sk,
    ws.ws_ship_mode_sk,
    i.i_item_id AS i_item_id,
    i.i_product_name AS i_product_name,
    i.i_color AS i_color,
    i.i_size AS i_size,
    i.i_brand AS i_brand,
    c.c_customer_id AS c_customer_id,
    c.c_first_name AS c_first_name,
    c.c_last_name AS c_last_name,
    c.c_email_address AS c_email_address,
    p.p_promo_name AS p_promo_name,
    wp.wp_url AS wp_url,
    wp.wp_type AS wp_type,
    wp.wp_char_count AS wp_char_count,
    w.web_site_id AS web_site_id,
    w.web_name AS web_name,
    d.d_date AS d_date,
    d.d_year AS d_year,
    sm.sm_ship_mode_id AS sm_ship_mode_id,
    sm.sm_type AS sm_type
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 1999
)
SELECT
  web_site_id,
  web_name,
  COUNT(*) AS sales_cnt,
  SUM(ws_net_paid) AS total_net_paid,
  SUM(length(concat_ws('#',
        CAST(ws_order_number AS VARCHAR),
        i_item_id,
        i_product_name,
        c_customer_id,
        c_email_address,
        p_promo_name,
        wp_url,
        sm_ship_mode_id,
        CAST(d_date AS VARCHAR)))) AS total_concat_len,
  AVG(cardinality(split(concat_ws('#',
        CAST(ws_order_number AS VARCHAR),
        i_item_id,
        i_product_name,
        c_customer_id,
        c_email_address,
        p_promo_name,
        wp_url,
        sm_ship_mode_id,
        CAST(d_date AS VARCHAR)), '#'))) AS avg_token_cnt,
  SUM(length(regexp_replace(lower(i_product_name), '[^a-z]', ''))) AS total_alpha_chars_product,
  SUM(length(regexp_replace(c_email_address, '[^0-9]', ''))) AS total_digits_in_email,
  SUM(CASE WHEN regexp_like(wp_url, '^https?://.*') THEN 1 ELSE 0 END) AS secure_url_cnt,
  AVG(length(substring(wp_url, 1, 20))) AS avg_url_prefix_len,
  SUM(length(replace(wp_type, ' ', ''))) AS total_wp_type_nospace_len,
  AVG(length(reverse(upper(i_brand)))) AS avg_rev_brand_len,
  SUM(length(trim(both ' ' FROM i_color))) AS total_color_len_trim,
  AVG(length(element_at(split(i_product_name, ' '), 1))) AS avg_first_word_len_product,
  SUM(length(regexp_replace(wp_url, '[^a-zA-Z]', ''))) AS total_alpha_chars_url,
  SUM(length(array_join(split(i_product_name, ' '), '-'))) AS total_joined_product_len
FROM sales
GROUP BY web_site_id, web_name
ORDER BY total_net_paid DESC
LIMIT 10
