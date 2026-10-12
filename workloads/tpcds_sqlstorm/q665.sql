SELECT d.d_year,
       i.i_category,
       SUM(CASE WHEN f.src = 'catalog' THEN f.net_paid ELSE 0 END) AS catalog_net_paid,
       SUM(CASE WHEN f.src = 'store' THEN f.net_paid ELSE 0 END) AS store_net_paid,
       SUM(CASE WHEN f.src = 'web' THEN f.net_paid ELSE 0 END) AS web_net_paid,
       SUM(f.net_paid) AS total_net_paid,
       SUM(f.net_profit) AS total_net_profit
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS src
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_paid,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
) f
JOIN date_dim d ON f.date_sk = d.d_date_sk
JOIN item i ON f.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category
