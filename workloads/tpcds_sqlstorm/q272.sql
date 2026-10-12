WITH daily_sales AS (
    SELECT ss_sold_date_sk AS date_sk, ss_net_profit AS profit, 'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk AS date_sk, cs_net_profit AS profit, 'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk, ws_net_profit AS profit, 'web' AS channel
    FROM web_sales
)
SELECT d.d_date, ds.channel, sum(ds.profit) AS total_profit
FROM daily_sales ds
JOIN date_dim d ON ds.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_date, ds.channel
ORDER BY d.d_date, ds.channel
