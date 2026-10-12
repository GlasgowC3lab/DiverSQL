WITH catalog_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        COUNT(*) AS catalog_orders
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sales_price > 50
      AND cd.cd_education_status = 'College'
      AND cd.cd_purchase_estimate >= 5000
    GROUP BY p.p_promo_name, sm.sm_type, cd.cd_gender
),
web_agg AS (
    SELECT
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode,
        cd.cd_gender AS gender,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sales_price > 50
      AND cd.cd_education_status = 'College'
      AND cd.cd_purchase_estimate >= 5000
    GROUP BY p.p_promo_name, sm.sm_type, cd.cd_gender
)
SELECT
    COALESCE(c.promo_name, w.promo_name) AS promo_name,
    COALESCE(c.ship_mode, w.ship_mode) AS ship_mode,
    COALESCE(c.gender, w.gender) AS gender,
    COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
    COALESCE(c.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0) AS total_net_paid,
    (COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) /
        NULLIF(COALESCE(c.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0), 0) AS profit_margin,
    COALESCE(c.catalog_orders, 0) + COALESCE(w.web_orders, 0) AS total_orders,
    RANK() OVER (ORDER BY (COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) DESC) AS profit_rank
FROM catalog_agg c
FULL OUTER JOIN web_agg w
    ON c.promo_name = w.promo_name
   AND c.ship_mode = w.ship_mode
   AND c.gender = w.gender
WHERE (COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) > 10000
ORDER BY total_net_profit DESC
LIMIT 20
