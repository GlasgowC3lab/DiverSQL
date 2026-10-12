SELECT
    d.d_year,
    i.i_category,
    s.channel,
    SUM(s.net_paid) AS total_sales,
    SUM(s.net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_net_paid,
           ss_net_profit,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_paid,
           ws_net_profit,
           'web'
    FROM web_sales
) s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category, s.channel
ORDER BY d.d_year, i.i_category, total_sales DESC
