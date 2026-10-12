WITH
cust_str AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        lower(c.c_email_address) AS email_lower,
        split(c.c_email_address, '@')[2] AS email_domain,
        length(split(c.c_email_address, '@')[2]) AS email_domain_len,
        (length(lower(c.c_first_name)) - length(regexp_replace(lower(c.c_first_name), '[aeiou]', '')) +
         length(lower(c.c_last_name)) - length(regexp_replace(lower(c.c_last_name), '[aeiou]', ''))) AS name_vowel_cnt,
        length(c.c_login) AS login_len,
        regexp_replace(c.c_login, '_', '-') AS login_normalized
    FROM customer c
),
item_str AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '') AS product_name_clean,
        length(regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '')) AS product_name_clean_len,
        cardinality(split(regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', ''), ' ')) AS product_name_token_cnt,
        i.i_item_desc,
        length(i.i_item_desc) AS item_desc_len,
        (length(i.i_item_desc) - length(regexp_replace(i.i_item_desc, '[AEIOUaeiou]', ''))) AS item_desc_vowel_cnt,
        ((length(i.i_item_desc) - length(regexp_replace(i.i_item_desc, '[AEIOUaeiou]', ''))) / nullif(length(i.i_item_desc), 0)) AS item_desc_vowel_ratio,
        i.i_color,
        regexp_replace(i.i_color, '[^A-Za-z]', '') AS color_alpha
    FROM item i
),
promo_str AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        regexp_replace(p.p_promo_name, '\\s+', ' ') AS promo_name_normalized,
        length(p.p_promo_name) AS promo_name_len,
        lower(p.p_channel_details) AS promo_channel_details_lower,
        replace(p.p_channel_details, '\\n', ' ') AS promo_channel_details_clean
    FROM promotion p
),
sales_str AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_coupon_amt,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
),
joined AS (
    SELECT
        c.c_customer_sk,
        c.full_name,
        c.email_lower,
        c.email_domain,
        c.email_domain_len,
        c.name_vowel_cnt,
        c.login_len,
        c.login_normalized,
        i.i_item_sk,
        i.i_item_id,
        i.product_name_clean,
        i.product_name_clean_len,
        i.product_name_token_cnt,
        i.item_desc_len,
        i.item_desc_vowel_cnt,
        i.item_desc_vowel_ratio,
        i.i_color,
        i.color_alpha,
        p.p_promo_sk,
        p.promo_name_normalized,
        p.promo_name_len,
        p.promo_channel_details_lower,
        s.ss_sold_date_sk,
        s.ss_quantity,
        s.ss_sales_price,
        s.ss_coupon_amt,
        s.ss_net_paid,
        s.ss_net_profit
    FROM cust_str c
    JOIN sales_str s ON c.c_customer_sk = s.ss_customer_sk
    JOIN item_str i ON i.i_item_sk = s.ss_item_sk
    LEFT JOIN promo_str p ON p.p_promo_sk = s.ss_promo_sk
),
agg AS (
    SELECT
        email_domain,
        COUNT(*) AS customer_count,
        AVG(login_len) AS avg_login_len,
        SUM(ss_net_profit) AS total_profit,
        MAX(name_vowel_cnt) AS max_name_vowel_cnt,
        MIN(item_desc_vowel_ratio) AS min_item_desc_vowel_ratio
    FROM joined
    GROUP BY email_domain
)
SELECT
    email_domain,
    customer_count,
    avg_login_len,
    total_profit,
    max_name_vowel_cnt,
    min_item_desc_vowel_ratio
FROM agg
ORDER BY total_profit DESC
LIMIT 10
