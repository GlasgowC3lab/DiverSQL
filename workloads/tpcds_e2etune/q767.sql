WITH agg AS (
    SELECT
        i.i_category AS category,
        sm.sm_type AS ship_mode,
        cp.cp_department AS department,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = cs.cs_sold_date_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND cp.cp_end_date_sk BETWEEN 2450800 AND 2451100
      AND cs.cs_sold_date_sk BETWEEN 2450800 AND 2451100
      AND p.p_discount_active = 'Y'
      AND i.i_category IS NOT NULL
    GROUP BY
        i.i_category,
        sm.sm_type,
        cp.cp_department
    HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
    category,
    ship_mode,
    department,
    orders,
    total_quantity,
    total_profit,
    avg_discount,
    avg_inventory_on_hand,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
