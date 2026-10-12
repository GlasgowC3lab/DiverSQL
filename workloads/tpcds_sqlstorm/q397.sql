WITH combined_sales AS (
    SELECT p.p_promo_id AS promo_id,
           cd.cd_gender AS gender,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT p.p_promo_id AS promo_id,
           cd.cd_gender AS gender,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT p.p_promo_id AS promo_id,
           cd.cd_gender AS gender,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT promo_id,
       gender,
       SUM(net_profit) AS total_net_profit,
       COUNT(*) AS transaction_count
FROM combined_sales
GROUP BY promo_id, gender
ORDER BY total_net_profit DESC
LIMIT 100
