WITH unified_sales AS (
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_promo_sk AS promo_sk,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_net_profit AS net_profit,
           'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_promo_sk,
           cs.cs_ext_sales_price,
           cs.cs_net_profit,
           'catalog'
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
)
SELECT d.d_year,
       i.i_category,
       i.i_class,
       s.sales_channel,
       SUM(s.ext_sales_price) AS total_sales,
       SUM(s.net_profit) AS total_profit,
       COUNT(*) AS order_count,
       AVG(p.p_cost) AS avg_promo_cost,
       (SUM(s.net_profit) / NULLIF(SUM(s.ext_sales_price), 0)) AS profit_rate
FROM unified_sales s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, i.i_category, i.i_class, s.sales_channel
ORDER BY total_sales DESC
LIMIT 100
