WITH
    sampled_store_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    filtered_sales AS (
        SELECT
            ss.ss_store_sk,
            i.i_item_id,
            i.i_item_desc,
            ss.ss_net_profit,
            s.s_city,
            s.s_store_name,
            CONCAT(s.s_store_name, ' - ', s.s_city) AS store_full_name,
            (
                SELECT avg(ss2.ss_net_profit)
                FROM store_sales ss2
                WHERE ss2.ss_item_sk = ss.ss_item_sk
            ) AS avg_item_profit
        FROM sampled_store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
          AND i.i_units LIKE '%Each%'
          AND ss.ss_net_profit > 0
    ),
    store_profit AS (
        SELECT
            ss_store_sk,
            store_full_name,
            SUM(ss_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM filtered_sales
        GROUP BY ss_store_sk, store_full_name
    ),
    excluded_stores AS (
        SELECT DISTINCT ss.ss_store_sk
        FROM sampled_store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, 'Test')
    ),
    low_sales AS (
        SELECT ss_store_sk, store_full_name, total_profit, sales_cnt
        FROM store_profit
        WHERE sales_cnt < 5
    )
SELECT hp.store_full_name,
       hp.total_profit,
       hp.sales_cnt
FROM store_profit hp
WHERE hp.ss_store_sk NOT IN (SELECT ss_store_sk FROM excluded_stores)
EXCEPT
SELECT ls.store_full_name,
       ls.total_profit,
       ls.sales_cnt
FROM low_sales ls
ORDER BY total_profit DESC
LIMIT 10
