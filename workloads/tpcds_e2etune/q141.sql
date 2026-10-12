WITH catalog_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451912 AND 2452276
      AND cs.cs_quantity > 20
      AND p.p_channel_email = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name, sm.sm_type
),
web_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451912 AND 2452276
      AND ws.ws_quantity > 20
      AND p.p_channel_email = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name, sm.sm_type
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    agg.p_promo_id,
    agg.p_promo_name,
    agg.ship_mode_type,
    agg.total_profit,
    agg.total_orders,
    agg.total_profit / SUM(agg.total_profit) OVER () AS profit_share,
    RANK() OVER (ORDER BY agg.total_profit DESC) AS profit_rank
FROM (
    SELECT
        p_promo_id,
        p_promo_name,
        ship_mode_type,
        SUM(total_net_profit) AS total_profit,
        SUM(order_cnt) AS total_orders
    FROM combined
    GROUP BY p_promo_id, p_promo_name, ship_mode_type
) agg
WHERE agg.total_profit > 10000
ORDER BY agg.total_profit DESC
LIMIT 10
