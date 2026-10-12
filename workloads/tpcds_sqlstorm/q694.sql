WITH combined_sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           cs.cs_sales_price AS sales_price
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           ws.ws_quantity,
           ws.ws_sales_price
    FROM web_sales ws
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           ss.ss_quantity,
           ss.ss_sales_price
    FROM store_sales ss
)
SELECT d.d_year,
       i.i_category,
       i.i_class,
       SUM(cs.net_profit) AS total_net_profit,
       SUM(cs.quantity) AS total_quantity,
       AVG(cs.sales_price) AS avg_sales_price
FROM combined_sales cs
JOIN date_dim d ON cs.sold_date_sk = d.d_date_sk
JOIN item i ON cs.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category, i.i_class
ORDER BY d.d_year, i.i_category, i.i_class
