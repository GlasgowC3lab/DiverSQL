WITH cs_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk, p.p_promo_name, sm.sm_type
),
ws_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk, p.p_promo_name, sm.sm_type
),
combined AS (
    SELECT * FROM cs_agg
    UNION ALL
    SELECT * FROM ws_agg
)
SELECT
    item_sk,
    sold_date_sk,
    channel,
    promo_name,
    ship_mode_type,
    total_net_paid,
    total_net_profit,
    CASE
        WHEN total_net_paid = 0 THEN 0
        ELSE total_net_profit / total_net_paid
    END AS profit_margin,
    CASE
        WHEN total_net_paid = 0 THEN 'No Sales'
        WHEN (total_net_profit / total_net_paid) < 0.05 THEN 'Low'
        WHEN (total_net_profit / total_net_paid) < 0.15 THEN 'Medium'
        ELSE 'High'
    END AS margin_category,
    DENSE_RANK() OVER (PARTITION BY sold_date_sk ORDER BY total_net_paid DESC) AS daily_sales_rank
FROM combined
WHERE total_net_paid > 0
ORDER BY sold_date_sk DESC, daily_sales_rank
