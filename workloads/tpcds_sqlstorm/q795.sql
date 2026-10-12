WITH joined AS (
    SELECT
        cc.cc_call_center_sk,
        s.s_store_sk,
        i.i_item_sk,
        p.p_promo_sk AS p_promo_sk,
        cc.cc_manager,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        cc.cc_zip,
        cc.cc_hours,
        cc.cc_street_number,
        cc.cc_street_name,
        cc.cc_street_type,
        cc.cc_suite_number,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_zip,
        s.s_street_number,
        s.s_street_name,
        s.s_street_type,
        s.s_suite_number,
        i.i_product_name,
        i.i_color,
        p.p_promo_name,
        p.p_discount_active
    FROM call_center cc
    JOIN store s ON cc.cc_state = s.s_state AND cc.cc_division = s.s_division_id
    JOIN item i ON (abs(cc.cc_call_center_sk - s.s_store_sk) % 1000) = (i.i_item_sk % 1000)
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE cc.cc_rec_start_date <= DATE '2024-10-01'
      AND (cc.cc_rec_end_date IS NULL OR cc.cc_rec_end_date >= DATE '2024-10-01')
      AND s.s_closed_date_sk IS NULL
)
SELECT
    cc_call_center_sk,
    s_store_sk,
    i_item_sk,
    p_promo_sk,
    format('%s|%s|%s|%s', upper(cc_manager), lower(s_store_name), lower(i_product_name), lower(p_promo_name)) AS full_key,
    length(format('%s|%s|%s|%s', upper(cc_manager), lower(s_store_name), lower(i_product_name), lower(p_promo_name))) AS full_key_len,
    regexp_replace(concat_ws('', cc_city, cc_state, cc_zip), '\\D', '') AS numeric_location,
    regexp_replace(cc_hours, '\\D', '') AS cleaned_hours,
    concat_ws(' ', lower(cc_street_name), upper(cc_street_type)) AS street_norm,
    reverse(cc_name) AS cc_name_rev,
    substring(i_product_name, 1, 5) AS prod_name_first5,
    substr(i_product_name, -5) AS prod_name_last5,
    translate(i_color, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') AS color_upper,
    CASE WHEN lower(i_color) LIKE '%red%' THEN 'RED' ELSE 'OTHER' END AS color_category,
    p_discount_active,
    p_promo_name,
    concat(i_product_name, ' - ', p_promo_name) AS combined_product_promo,
    concat_ws(' ', cc_street_number, cc_street_name, cc_street_type,
        COALESCE(concat('Suite', cc_suite_number), '')) AS cc_full_address,
    length(concat_ws(' ', cc_street_number, cc_street_name, cc_street_type,
        COALESCE(concat('Suite', cc_suite_number), ''))) AS cc_full_address_len,
    concat_ws(' ', s_street_number, s_street_name, s_street_type,
        COALESCE(concat('Suite', s_suite_number), '')) AS store_full_address,
    length(concat_ws(' ', s_street_number, s_street_name, s_street_type,
        COALESCE(concat('Suite', s_suite_number), ''))) AS store_full_address_len
FROM joined
ORDER BY cc_call_center_sk
LIMIT 1000
