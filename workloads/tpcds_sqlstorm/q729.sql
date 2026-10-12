WITH all_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_net_profit
    FROM web_sales ws
),
sales_agg AS (
    SELECT d.d_year,
           d.d_moy,
           i.i_item_id AS item_id,
           i.i_product_name AS product_name,
           SUM(a.net_profit) AS total_net_profit
    FROM all_sales a
    JOIN date_dim d ON a.date_sk = d.d_date_sk
    JOIN item i ON a.item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_moy, i.i_item_id, i.i_product_name
)
SELECT d_year,
       d_moy,
       item_id,
       product_name,
       total_net_profit
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY d_year, d_moy ORDER BY total_net_profit DESC) AS rn
    FROM sales_agg
) t
WHERE rn <= 10
ORDER BY d_year, d_moy, total_net_profit DESC
