WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_sk,
        p.p_channel_details,
        s.s_store_id,
        s.s_city,
        CONCAT(s.s_store_id, '-', p.p_promo_id) AS store_promo_key,
        SUM(ss.ss_net_profit) AS total_net_profit,
        REGEXP_EXTRACT(p.p_channel_details, '(\\w+) respon', 1) AS extracted_word
    FROM
        store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        REGEXP_LIKE(p.p_channel_details, 'high')
        AND s.s_city LIKE 'A%'
    GROUP BY
        p.p_promo_id,
        p.p_promo_sk,
        p.p_channel_details,
        s.s_store_id,
        s.s_city,
        REGEXP_EXTRACT(p.p_channel_details, '(\\w+) respon', 1)
)
SELECT
    p_promo_id,
    s_store_id,
    store_promo_key,
    extracted_word,
    total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_net_profit DESC) AS promo_rank
FROM sales_agg
ORDER BY promo_rank, total_net_profit DESC
LIMIT 100
