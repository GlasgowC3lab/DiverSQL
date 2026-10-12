WITH
    item_strings AS (
        SELECT
            i_item_sk,
            lower(regexp_replace(concat_ws(' ',
                i.i_product_name,
                i.i_item_desc,
                i.i_color,
                i.i_size,
                i.i_units), '[^a-z0-9 ]', '')) AS normalized_item_text,
            length(regexp_replace(concat_ws(' ',
                i.i_product_name,
                i.i_item_desc,
                i.i_color,
                i.i_size,
                i.i_units), '[^a-z0-9 ]', '')) AS text_length,
            cardinality(regexp_split(regexp_replace(concat_ws(' ',
                i.i_product_name,
                i.i_item_desc,
                i.i_color,
                i.i_size,
                i.i_units), '[^a-z0-9 ]', ''), '\\s+')) AS token_count,
            substr(i.i_item_id, 1, 5) AS item_id_prefix
        FROM item i
    ),
    customer_strings AS (
        SELECT
            c_customer_sk,
            lower(concat_ws(' ', c.c_first_name, c.c_last_name)) AS lower_full_name,
            length(c.c_first_name) AS first_name_len,
            length(c.c_last_name) AS last_name_len,
            lower(c.c_email_address) AS email_lower,
            regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
            CASE WHEN regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.com$') THEN 'valid_com' ELSE 'invalid' END AS email_valid_flag
        FROM customer c
    ),
    address_strings AS (
        SELECT
            ca_address_sk,
            lower(regexp_replace(concat_ws(' ',
                ca_street_number,
                ca_street_name,
                ca_street_type,
                ca_suite_number,
                ca_city,
                ca_state,
                ca_zip), '[^a-z0-9 ]', '')) AS normalized_address,
            length(regexp_replace(concat_ws(' ',
                ca_street_number,
                ca_street_name,
                ca_street_type,
                ca_suite_number,
                ca_city,
                ca_state,
                ca_zip), '[^a-z0-9 ]', '')) AS address_len,
            cardinality(regexp_split(regexp_replace(concat_ws(' ',
                ca_street_number,
                ca_street_name,
                ca_street_type,
                ca_suite_number,
                ca_city,
                ca_state,
                ca_zip), '[^a-z0-9 ]', ''), '\\s+')) AS address_token_count
        FROM customer_address ca
    ),
    sales_combined AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_customer_sk,
            ss.ss_item_sk,
            ss.ss_quantity,
            ss.ss_net_paid,
            ss.ss_net_profit,
            row_number() OVER (PARTITION BY ss.ss_customer_sk ORDER BY ss.ss_net_paid DESC) AS rn
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451500
    )
SELECT
    sc.ss_ticket_number,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.lower_full_name,
    cs.email_lower,
    cs.email_domain,
    cs.email_valid_flag,
    itm.normalized_item_text,
    itm.text_length,
    itm.token_count,
    itm.item_id_prefix,
    addr.normalized_address,
    addr.address_len,
    addr.address_token_count,
    sc.ss_quantity,
    sc.ss_net_paid,
    sc.ss_net_profit,
    round(sc.ss_net_paid / nullif(sc.ss_quantity, 0), 2) AS avg_price_per_item,
    substr(c.c_login, 1, 3) AS login_prefix,
    regexp_replace(c.c_login, '[0-9]', '') AS login_alpha_only,
    CASE WHEN position('a' IN lower(itm.normalized_item_text)) > 0 THEN 'has_a' ELSE 'no_a' END AS a_in_item,
    CASE WHEN position('e' IN lower(cs.email_lower)) > 0 THEN 'email_has_e' ELSE 'email_no_e' END AS e_in_email
FROM sales_combined sc
JOIN customer c ON sc.ss_customer_sk = c.c_customer_sk
JOIN customer_strings cs ON c.c_customer_sk = cs.c_customer_sk
JOIN item_strings itm ON sc.ss_item_sk = itm.i_item_sk
JOIN address_strings addr ON c.c_current_addr_sk = addr.ca_address_sk
WHERE sc.rn <= 10
ORDER BY sc.ss_net_paid DESC
LIMIT 50
