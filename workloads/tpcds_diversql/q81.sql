WITH
catalog_part AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        w_cat.w_warehouse_name,
        p.p_promo_name,
        i_cat.i_category,
        cc.cc_name AS call_center_name,
        cp.cp_department,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN warehouse w_cat ON cs.cs_warehouse_sk = w_cat.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i_cat ON cs.cs_item_sk = i_cat.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i_cat.i_item_sk
        AND inv.inv_warehouse_sk = w_cat.w_warehouse_sk
    WHERE cs.cs_call_center_sk IN (
        SELECT cc2.cc_call_center_sk
        FROM call_center cc2
        WHERE cc2.cc_state = 'CA'
    )
),
web_part AS (
    SELECT
        ws.ws_warehouse_sk AS warehouse_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        w_web.w_warehouse_name,
        p.p_promo_name,
        i_web.i_category,
        wp.wp_type,
        site.web_market_manager,
        inv.inv_quantity_on_hand
    FROM web_sales ws
    JOIN warehouse w_web ON ws.ws_warehouse_sk = w_web.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i_web ON ws.ws_item_sk = i_web.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    FULL OUTER JOIN inventory inv
        ON inv.inv_item_sk = i_web.i_item_sk
        AND inv.inv_warehouse_sk = w_web.w_warehouse_sk
    WHERE ws.ws_web_site_sk IN (
        SELECT s.web_site_sk
        FROM web_site s
        WHERE s.web_market_manager = 'Kelvin Lynch'
    )
)
SELECT
    u.w_warehouse_name,
    u.p_promo_name,
    u.i_category,
    SUM(u.cs_quantity) AS total_quantity,
    SUM(u.cs_net_profit) AS total_net_profit,
    SUM(u.inv_quantity_on_hand) AS total_inventory_on_hand
FROM (
    SELECT
        warehouse_sk,
        promo_sk,
        cs_quantity,
        cs_net_profit,
        w_warehouse_name,
        p_promo_name,
        i_category,
        inv_quantity_on_hand
    FROM catalog_part
    UNION DISTINCT
    SELECT
        warehouse_sk,
        promo_sk,
        ws_quantity AS cs_quantity,
        ws_net_profit AS cs_net_profit,
        w_warehouse_name,
        p_promo_name,
        i_category,
        inv_quantity_on_hand
    FROM web_part
) u
GROUP BY
    u.w_warehouse_name,
    u.p_promo_name,
    u.i_category
ORDER BY total_net_profit DESC
LIMIT 100
