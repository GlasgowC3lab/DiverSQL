WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS store_item_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (5)
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
)
SELECT
    s.s_store_name,
    i.i_product_name,
    sa.store_item_profit,
    CASE
        WHEN sa.store_item_profit > 10000 THEN 'HIGH'
        WHEN sa.store_item_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT avg(ss2.ss_net_profit) FROM store_sales ss2) AS avg_net_profit_all,
    REGEXP_EXTRACT(i.i_product_name, '(\\w+)-\\w+$', 1) AS product_prefix,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location
FROM sales_agg sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
WHERE REGEXP_LIKE(i.i_product_name, '^\\w+-\\w+$')
  AND s.s_store_name LIKE '%pri%'
  AND CONCAT(s.s_city, ', ', s.s_state) LIKE '%York%'
ORDER BY sa.store_item_profit DESC
LIMIT 100
