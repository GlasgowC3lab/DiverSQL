WITH agg_customer_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promo_used
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY s.s_store_sk, s.s_store_name, c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    s_store_sk,
    s_store_name,
    c_customer_id,
    customer_name,
    total_net_profit,
    total_discount,
    transaction_count,
    distinct_promo_used,
    profit_rank,
    profit_category
FROM (
    SELECT
        s_store_sk,
        s_store_name,
        c_customer_id,
        customer_name,
        total_net_profit,
        total_discount,
        transaction_count,
        distinct_promo_used,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY total_net_profit DESC) AS profit_rank,
        CASE WHEN total_net_profit > 10000 THEN 'High' ELSE 'Normal' END AS profit_category
    FROM agg_customer_store
) t
WHERE profit_rank <= 5
ORDER BY s_store_sk, profit_rank
