SELECT d.d_year,
       i.i_category,
       i.i_class,
       i.i_brand,
       SUM(CASE WHEN s.channel = 'store' THEN s.net_paid ELSE 0 END) AS store_sales,
       SUM(CASE WHEN s.channel = 'catalog' THEN s.net_paid ELSE 0 END) AS catalog_sales,
       SUM(CASE WHEN s.channel = 'web' THEN s.net_paid ELSE 0 END) AS web_sales,
       SUM(CASE WHEN s.channel = 'store' THEN s.net_profit ELSE 0 END) AS store_profit,
       SUM(CASE WHEN s.channel = 'catalog' THEN s.net_profit ELSE 0 END) AS catalog_profit,
       SUM(CASE WHEN s.channel = 'web' THEN s.net_profit ELSE 0 END) AS web_profit
FROM (
   SELECT ss_sold_date_sk AS date_sk,
          ss_item_sk AS item_sk,
          ss_net_paid AS net_paid,
          ss_net_profit AS net_profit,
          'store' AS channel
   FROM store_sales
   UNION ALL
   SELECT cs_sold_date_sk AS date_sk,
          cs_item_sk AS item_sk,
          cs_net_paid AS net_paid,
          cs_net_profit AS net_profit,
          'catalog' AS channel
   FROM catalog_sales
   UNION ALL
   SELECT ws_sold_date_sk AS date_sk,
          ws_item_sk AS item_sk,
          ws_net_paid AS net_paid,
          ws_net_profit AS net_profit,
          'web' AS channel
   FROM web_sales
) s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
ORDER BY d.d_year, i.i_category, i.i_class, i.i_brand
