WITH store_daily AS (
    SELECT d.d_date AS sale_date,
           'store' AS channel,
           p.p_promo_name AS promo_name,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, p.p_promo_name
),
web_daily AS (
    SELECT d.d_date AS sale_date,
           'web' AS channel,
           p.p_promo_name AS promo_name,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, p.p_promo_name
),
combined AS (
    SELECT sale_date, channel, promo_name, net_profit FROM store_daily
    UNION ALL
    SELECT sale_date, channel, promo_name, net_profit FROM web_daily
)
SELECT sale_date,
       channel,
       promo_name,
       net_profit,
       SUM(net_profit) OVER (PARTITION BY channel ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_profit
FROM combined
ORDER BY sale_date, channel
LIMIT 100
