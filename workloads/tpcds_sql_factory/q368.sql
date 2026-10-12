WITH catalog_sales_combined AS (
    SELECT
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
web_sales_combined AS (
    SELECT
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
all_sales AS (
    SELECT * FROM catalog_sales_combined
    UNION ALL
    SELECT * FROM web_sales_combined
)
SELECT
    sm.sm_type AS ship_mode_type,
    SUM(a.net_profit) AS total_net_profit,
    COUNT(DISTINCT a.order_number) AS distinct_orders,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN a.net_profit ELSE 0 END) AS discount_active_profit,
    CASE
        WHEN SUM(a.net_profit) = 0 THEN 0
        ELSE SUM(CASE WHEN p.p_discount_active = 'Y' THEN a.net_profit ELSE 0 END) / SUM(a.net_profit)
    END AS discount_active_profit_ratio,
    RANK() OVER (ORDER BY SUM(a.net_profit) DESC) AS profit_rank
FROM all_sales a
JOIN promotion p ON a.promo_sk = p.p_promo_sk
JOIN ship_mode sm ON a.ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY sm.sm_type
ORDER BY profit_rank
