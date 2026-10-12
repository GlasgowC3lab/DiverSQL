WITH all_sales AS (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_promo_sk,
           ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_promo_sk,
           ws.ws_net_profit
    FROM web_sales ws
), joined AS (
    SELECT d.d_year,
           i.i_category,
           p.p_promo_name,
           SUM(s.net_profit) AS total_profit
    FROM all_sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    GROUP BY d.d_year, i.i_category, p.p_promo_name
), ranked AS (
    SELECT d_year,
           i_category,
           p_promo_name,
           total_profit,
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rn
    FROM joined
)
SELECT d_year,
       i_category,
       p_promo_name,
       total_profit
FROM ranked
WHERE rn <= 10
ORDER BY d_year, total_profit DESC
