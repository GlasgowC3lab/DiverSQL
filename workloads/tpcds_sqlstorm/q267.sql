SELECT 
    i.i_brand,
    d.d_year,
    d.d_month_seq,
    SUM(f.net_profit) AS total_net_profit,
    COUNT(*) AS total_sales
FROM (
    SELECT ss.ss_sold_date_sk AS date_sk, ss.ss_item_sk AS item_sk, ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk, ws.ws_item_sk AS item_sk, ws.ws_net_profit AS net_profit
    FROM web_sales ws
) f
JOIN date_dim d ON f.date_sk = d.d_date_sk
JOIN item i ON f.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY i.i_brand, d.d_year, d.d_month_seq
ORDER BY i.i_brand, d.d_year, d.d_month_seq
