WITH sales_union AS (
    SELECT cs.cs_net_profit AS net_profit,
           cs.cs_promo_sk AS promo_sk,
           d.d_year AS year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
    UNION ALL
    SELECT ss.ss_net_profit AS net_profit,
           ss.ss_promo_sk AS promo_sk,
           d.d_year AS year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
    UNION ALL
    SELECT ws.ws_net_profit AS net_profit,
           ws.ws_promo_sk AS promo_sk,
           d.d_year AS year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
)
SELECT p.p_promo_name,
       s.year,
       SUM(s.net_profit) AS total_net_profit,
       COUNT(*) AS total_transactions
FROM sales_union s
JOIN promotion p ON s.promo_sk = p.p_promo_sk
GROUP BY p.p_promo_name, s.year
ORDER BY total_net_profit DESC
LIMIT 10
