WITH cat_agg AS (
    SELECT
        cc.cc_mkt_class AS market_class,
        sm.sm_type AS ship_type,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS cat_orders
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_state = 'TN'
      AND sm.sm_type IN ('AIR', 'RAIL')
    GROUP BY cc.cc_mkt_class, sm.sm_type
),
web_agg AS (
    SELECT
        sm.sm_type AS ship_type,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE wsit.web_country = 'US'
      AND sm.sm_type IN ('AIR', 'RAIL')
    GROUP BY sm.sm_type
)
SELECT
    cat.market_class,
    cat.ship_type,
    cat.cat_net_profit,
    web.web_net_profit,
    cat.cat_net_profit + web.web_net_profit AS total_net_profit,
    web.web_net_profit / NULLIF(cat.cat_net_profit, 0) AS web_to_cat_profit_ratio,
    RANK() OVER (ORDER BY (cat.cat_net_profit + web.web_net_profit) DESC) AS profit_rank
FROM cat_agg cat
JOIN web_agg web ON cat.ship_type = web.ship_type
WHERE cat.cat_orders > 100
  AND web.web_orders > 50
ORDER BY total_net_profit DESC
LIMIT 50
