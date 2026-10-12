WITH agg AS (
    SELECT
        p.p_promo_name,
        i.inv_warehouse_sk,
        COUNT(*) AS transaction_cnt,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        AVG(i.inv_quantity_on_hand) AS avg_qty,
        SUM(p.p_cost) AS total_promo_cost,
        ROUND(AVG(i.inv_quantity_on_hand) * SUM(p.p_cost), 2) AS weighted_cost
    FROM promotion p
    JOIN inventory i
        ON p.p_item_sk = i.inv_item_sk
    WHERE i.inv_date_sk BETWEEN 2450800 AND 2451100
      AND p.p_start_date_sk <= i.inv_date_sk
      AND p.p_end_date_sk >= i.inv_date_sk
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, i.inv_warehouse_sk
    HAVING COUNT(*) > 5
)
SELECT
    p_promo_name,
    inv_warehouse_sk,
    transaction_cnt,
    total_qty,
    avg_qty,
    total_promo_cost,
    weighted_cost,
    RANK() OVER (PARTITION BY inv_warehouse_sk ORDER BY total_qty DESC) AS warehouse_qty_rank
FROM agg
ORDER BY total_qty DESC
LIMIT 50
