WITH combined_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid_inc_tax AS net_paid,
           cs.cs_net_profit AS profit,
           cs.cs_quantity AS quantity,
           cs.cs_promo_sk AS promo_sk,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_paid_inc_tax,
           ss.ss_net_profit,
           ss.ss_quantity,
           ss.ss_promo_sk,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_paid_inc_tax,
           ws.ws_net_profit,
           ws.ws_quantity,
           ws.ws_promo_sk,
           'web'
    FROM web_sales ws
)
SELECT d.d_year,
       i.i_category,
       cs.channel,
       SUM(cs.net_paid) AS total_net_paid,
       SUM(cs.profit) AS total_profit,
       SUM(cs.quantity) AS total_quantity,
       COUNT(DISTINCT cs.item_sk) AS distinct_items_sold,
       COUNT(DISTINCT cs.promo_sk) AS distinct_promotions
FROM combined_sales cs
JOIN date_dim d ON cs.date_sk = d.d_date_sk
JOIN item i ON cs.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category, cs.channel
ORDER BY d.d_year, i.i_category, cs.channel
