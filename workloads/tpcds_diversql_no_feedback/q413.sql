WITH combined_sales AS (
   SELECT d.d_year,
          i.i_category,
          'catalog' AS sales_channel,
          SUM(cs.cs_net_profit) AS total_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
     AND i.i_category = 'Sports'
   GROUP BY d.d_year, i.i_category
   UNION ALL
   SELECT d.d_year,
          i.i_category,
          'web' AS sales_channel,
          SUM(ws.ws_net_profit) AS total_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
     AND i.i_category = 'Sports'
   GROUP BY d.d_year, i.i_category
)
SELECT d_year,
       i_category,
       sales_channel,
       total_profit
FROM combined_sales
ORDER BY d_year, sales_channel
