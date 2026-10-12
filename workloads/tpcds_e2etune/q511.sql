WITH inv_agg AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
    GROUP BY inv.inv_item_sk
),
promo_agg AS (
    SELECT
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost,
        MAX(p.p_end_date_sk) - MIN(p.p_start_date_sk) AS promo_window_days
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_start_date_sk >= 2450806
      AND p.p_end_date_sk <= 2451063
    GROUP BY p.p_item_sk
)
SELECT
    i.i_category,
    i.i_brand,
    i.i_item_id,
    inv.total_qty,
    inv.total_inventory_value,
    promo.promo_cnt,
    promo.total_promo_cost,
    CASE
        WHEN inv.total_inventory_value > 0 THEN promo.total_promo_cost / inv.total_inventory_value
        ELSE NULL
    END AS promo_cost_to_inventory_ratio
FROM inv_agg inv
JOIN promo_agg promo ON inv.inv_item_sk = promo.p_item_sk
JOIN item i ON i.i_item_sk = inv.inv_item_sk
WHERE inv.total_qty > 500
ORDER BY promo_cost_to_inventory_ratio DESC NULLS LAST
LIMIT 20
