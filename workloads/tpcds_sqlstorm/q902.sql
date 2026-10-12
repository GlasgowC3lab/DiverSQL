WITH item_metrics AS (
    SELECT
        i_item_sk,
        lower(i_product_name) AS prod_name_lower,
        regexp_replace(i_product_name, '[^a-z0-9]', '') AS prod_name_alphanum,
        length(regexp_replace(i_product_name, '[^aeiouAEIOU]', '')) AS prod_vowel_count,
        reverse(i_product_name) AS prod_name_rev,
        array_join(array_sort(split(i_product_name, ' ')), '-') AS prod_name_sorted_words,
        substring(regexp_replace(i_product_name, '[^a-z0-9]', ''), 1, 5) AS prod_name_prefix
    FROM item
),
store_metrics AS (
    SELECT
        s_store_sk,
        concat_ws(', ', s_store_name, s_city, s_state) AS store_full_address,
        lower(s_store_name) AS store_name_lower,
        replace(s_store_name, ' ', '_') AS store_name_underscored,
        length(regexp_replace(s_store_name, '[^AEIOUaeiou]', '')) AS store_vowel_count,
        reverse(s_store_name) AS store_name_rev,
        regexp_extract(s_zip, '(\\d{5})', 1) AS zip5
    FROM store
),
promotion_metrics AS (
    SELECT
        p_promo_sk,
        lower(p_promo_name) AS promo_name_lower,
        regexp_replace(p_promo_name, '[^a-z0-9]', '') AS promo_name_alphanum,
        length(regexp_replace(p_promo_name, '[^aeiouAEIOU]', '')) AS promo_vowel_count,
        reverse(p_promo_name) AS promo_name_rev,
        substring(regexp_replace(p_promo_name, '[^a-z0-9]', ''), 1, 4) AS promo_name_prefix
    FROM promotion
),
sales_base AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_ticket_number AS ticket_num,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_order_number AS ticket_num,
        CAST(NULL AS integer) AS store_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_order_number AS ticket_num,
        CAST(NULL AS integer) AS store_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
),
final AS (
    SELECT
        sb.ticket_num,
        d.d_date,
        COALESCE(st.store_full_address, 'N/A') AS store_address,
        im.prod_name_alphanum,
        im.prod_vowel_count,
        im.prod_name_rev,
        im.prod_name_sorted_words,
        im.prod_name_prefix,
        position('e' IN im.prod_name_alphanum) AS pos_e,
        replace(im.prod_name_alphanum, 'a', '@') AS prod_name_a_replaced,
        pm.promo_name_alphanum,
        pm.promo_vowel_count,
        pm.promo_name_rev,
        pm.promo_name_prefix,
        concat(im.prod_name_alphanum, '_', pm.promo_name_alphanum) AS combined_key,
        round(sb.net_paid, 2) AS net_paid,
        round(sb.net_profit, 2) AS net_profit,
        length(st.store_name_underscored) AS store_name_underscored_len,
        st.store_vowel_count,
        st.zip5
    FROM sales_base sb
    LEFT JOIN date_dim d ON sb.date_sk = d.d_date_sk
    LEFT JOIN item_metrics im ON sb.item_sk = im.i_item_sk
    LEFT JOIN store_metrics st ON sb.store_sk = st.s_store_sk
    LEFT JOIN promotion_metrics pm ON sb.promo_sk = pm.p_promo_sk
    WHERE
        (im.prod_name_alphanum IS NOT NULL AND regexp_like(im.prod_name_alphanum, '^a.*'))
        OR (pm.promo_name_alphanum IS NOT NULL AND regexp_like(pm.promo_name_alphanum, 'promo$'))
)
SELECT *
FROM final
WHERE net_profit > 0
ORDER BY net_profit DESC
LIMIT 100
