WITH daily_sales AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        'catalog' AS channel
    FROM catalog_sales cs
    GROUP BY cs.cs_promo_sk, cs.cs_sold_date_sk
    UNION ALL
    SELECT
        ws.ws_promo_sk AS promo_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        SUM(ws.ws_net_paid) AS daily_net_paid,
        'web' AS channel
    FROM web_sales ws
    GROUP BY ws.ws_promo_sk, ws.ws_sold_date_sk
),
promo_daily AS (
    SELECT
        p.p_promo_name AS promo_name,
        ds.sold_date_sk,
        ds.channel,
        ds.daily_net_paid,
        SUM(ds.daily_net_paid) OVER (PARTITION BY p.p_promo_name, ds.channel ORDER BY ds.sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
        LAG(ds.daily_net_paid) OVER (PARTITION BY p.p_promo_name, ds.channel ORDER BY ds.sold_date_sk) AS prev_daily_net_paid
    FROM daily_sales ds
    JOIN promotion p ON ds.promo_sk = p.p_promo_sk
)
SELECT
    promo_name,
    sold_date_sk,
    channel,
    daily_net_paid,
    cumulative_net_paid,
    CASE
        WHEN prev_daily_net_paid IS NULL THEN NULL
        WHEN prev_daily_net_paid = 0 THEN NULL
        WHEN (daily_net_paid - prev_daily_net_paid) / prev_daily_net_paid >= 0.2 THEN 'Significant Increase'
        ELSE 'Normal'
    END AS change_flag
FROM promo_daily
WHERE daily_net_paid > 0
ORDER BY promo_name, channel, sold_date_sk
