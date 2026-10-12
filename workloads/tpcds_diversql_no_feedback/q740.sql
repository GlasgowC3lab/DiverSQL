WITH sampled_items AS (
    SELECT i_item_sk,
           i_item_desc,
           i_category,
           i_brand
    FROM item TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_city,
    si.i_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_net_profit) AS total_net_profit,
    ROUND(AVG(ss.ss_sales_price), 2) AS avg_sales_price,
    CONCAT('Category ', si.i_category, ' in ', s.s_city) AS description
FROM store_sales ss
JOIN sampled_items si
    ON ss.ss_item_sk = si.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
WHERE regexp_like(si.i_item_desc, '[A-Z]{3}')
  AND s.s_city LIKE 'S%'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_item_sk = ss.ss_item_sk
          AND ws.ws_net_profit > 0
    )
GROUP BY
    s.s_city,
    si.i_category,
    CONCAT('Category ', si.i_category, ' in ', s.s_city)
ORDER BY total_net_profit DESC
LIMIT 20
