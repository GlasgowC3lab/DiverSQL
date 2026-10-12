WITH cat_agg AS (
    SELECT
        cs.cs_ship_mode_sk AS ship_mode_sk,
        SUM(cs.cs_net_paid_inc_tax) AS cat_rev,
        SUM(cs.cs_ext_discount_amt) AS cat_discount,
        SUM(cs.cs_quantity) AS cat_qty
    FROM catalog_sales cs
    WHERE cs.cs_promo_sk IN (1023, 1057)
    GROUP BY cs.cs_ship_mode_sk
),
web_agg AS (
    SELECT
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_web_site_sk AS web_site_sk,
        SUM(ws.ws_net_paid_inc_tax) AS web_rev,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    WHERE ws.ws_promo_sk IN (1023, 1057)
    GROUP BY ws.ws_ship_mode_sk, ws.ws_web_site_sk
),
inv_agg AS (
    SELECT
        ship_mode_sk,
        AVG(inv_quantity_on_hand) AS avg_inv_qty
    FROM (
        SELECT cs.cs_ship_mode_sk AS ship_mode_sk, inv.inv_quantity_on_hand
        FROM catalog_sales cs
        JOIN inventory inv ON cs.cs_item_sk = inv.inv_item_sk AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
        UNION ALL
        SELECT ws.ws_ship_mode_sk AS ship_mode_sk, inv.inv_quantity_on_hand
        FROM web_sales ws
        JOIN inventory inv ON ws.ws_item_sk = inv.inv_item_sk AND ws.ws_warehouse_sk = inv.inv_warehouse_sk
    ) combined
    GROUP BY ship_mode_sk
)
SELECT
    sm.sm_type,
    wsit.web_name,
    cat.cat_rev AS total_catalog_revenue,
    web.web_rev AS total_web_revenue,
    cat.cat_discount + web.web_discount AS total_discount_amount,
    cat.cat_qty + web.web_qty AS total_units_sold,
    COALESCE(inv.avg_inv_qty, 0) AS avg_inventory_on_hand,
    ROUND((cat.cat_rev + web.web_rev) / NULLIF(cat.cat_qty + web.web_qty, 0), 2) AS avg_revenue_per_unit
FROM cat_agg cat
JOIN ship_mode sm ON cat.ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_agg web ON cat.ship_mode_sk = web.ship_mode_sk
JOIN web_site wsit ON web.web_site_sk = wsit.web_site_sk
LEFT JOIN inv_agg inv ON cat.ship_mode_sk = inv.ship_mode_sk
WHERE cat.cat_qty + web.web_qty > 500
ORDER BY total_web_revenue DESC
LIMIT 15
