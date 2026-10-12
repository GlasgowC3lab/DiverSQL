WITH combined_sales AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          NULL AS store_sk,
          cs.cs_net_profit AS net_profit,
          cs.cs_quantity AS quantity,
          cs.cs_ext_sales_price AS ext_sales_price
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          ss.ss_item_sk,
          ss.ss_store_sk,
          ss.ss_net_profit,
          ss.ss_quantity,
          ss.ss_ext_sales_price
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_item_sk,
          NULL,
          ws.ws_net_profit,
          ws.ws_quantity,
          ws.ws_ext_sales_price
   FROM web_sales ws
)
SELECT d.d_year,
       s.s_store_name,
       i.i_category,
       SUM(c.net_profit) AS total_net_profit,
       SUM(c.ext_sales_price) AS total_sales,
       COUNT(DISTINCT c.item_sk) AS distinct_items_sold
FROM combined_sales c
JOIN date_dim d ON c.date_sk = d.d_date_sk
LEFT JOIN store s ON c.store_sk = s.s_store_sk
JOIN item i ON c.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY GROUPING SETS ((d.d_year, s.s_store_name, i.i_category),
                       (d.d_year, s.s_store_name),
                       (d.d_year, i.i_category),
                       (d.d_year),
                       ())
ORDER BY total_net_profit DESC
LIMIT 100
