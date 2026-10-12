WITH all_sales AS (
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           CAST(NULL AS integer) AS store_sk,
           ws.ws_item_sk,
           ws.ws_net_profit
    FROM web_sales ws
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           CAST(NULL AS integer) AS store_sk,
           cs.cs_item_sk,
           cs.cs_net_profit
    FROM catalog_sales cs
)
SELECT d.d_year,
       COALESCE(s.s_state, 'WEB') AS store_state,
       i.i_category,
       SUM(all_sales.net_profit) AS total_profit
FROM all_sales
JOIN date_dim d ON all_sales.sold_date_sk = d.d_date_sk
JOIN item i ON all_sales.item_sk = i.i_item_sk
LEFT JOIN store s ON all_sales.store_sk = s.s_store_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, COALESCE(s.s_state, 'WEB'), i.i_category
ORDER BY total_profit DESC
LIMIT 100
