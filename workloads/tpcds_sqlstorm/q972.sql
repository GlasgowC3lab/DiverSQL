WITH unioned AS (
    SELECT
        cs.cs_order_number AS order_number,
        'catalog' AS channel,
        d.d_year,
        d.d_month_seq,
        cs.cs_net_paid AS net_paid,
        i.i_product_name,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_name,
        cc.cc_name,
        concat_ws(' ', i.i_product_name, i.i_item_desc, c.c_first_name, c.c_last_name, p.p_promo_name, cc.cc_name) AS full_text
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT
        ws.ws_order_number AS order_number,
        'web' AS channel,
        d.d_year,
        d.d_month_seq,
        ws.ws_net_paid AS net_paid,
        i.i_product_name,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_name,
        wp.wp_url,
        concat_ws(' ', i.i_product_name, i.i_item_desc, c.c_first_name, c.c_last_name, p.p_promo_name, wp.wp_url) AS full_text
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk

    UNION ALL

    SELECT
        ss.ss_ticket_number AS order_number,
        'store' AS channel,
        d.d_year,
        d.d_month_seq,
        ss.ss_net_paid AS net_paid,
        i.i_product_name,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        p.p_promo_name,
        s.s_store_name,
        concat_ws(' ', i.i_product_name, i.i_item_desc, c.c_first_name, c.c_last_name, p.p_promo_name, s.s_store_name) AS full_text
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
)
SELECT
    channel,
    d_year,
    d_month_seq,
    COUNT(*) AS txn_count,
    SUM(net_paid) AS total_net,
    AVG(LENGTH(full_text)) AS avg_full_text_len,
    APPROX_PERCENTILE(LENGTH(full_text), 0.5) AS median_full_text_len,
    AVG(cardinality(regexp_split(full_text, '\\s+'))) AS avg_word_count,
    SUM(CASE WHEN regexp_like(full_text, '[A-Z]{3}[0-9]{3}') THEN 1 ELSE 0 END) AS pattern_match_count,
    MAX(LENGTH(regexp_replace(full_text, '[^A-Za-z0-9]', ''))) AS max_alnum_len,
    APPROX_PERCENTILE(LENGTH(regexp_replace(lower(trim(full_text)), '[[:space:]]+', '_')), 0.9) AS p90_normalized_len,
    APPROX_DISTINCT(full_text) AS approx_distinct_full_text,
    COUNT(DISTINCT order_number) FILTER (WHERE LENGTH(full_text) > 100) AS long_txn_count
FROM unioned
GROUP BY
    channel,
    d_year,
    d_month_seq
ORDER BY
    channel,
    d_year,
    d_month_seq
