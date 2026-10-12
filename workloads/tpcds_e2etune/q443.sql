SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_item_cnt,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    AVG(i.inv_quantity_on_hand) AS avg_qty_per_item,
    SUM(
        i.inv_quantity_on_hand *
        COALESCE(
            (
                SELECT AVG(p.p_cost)
                FROM promotion p
                WHERE p.p_item_sk = i.inv_item_sk
                  AND p.p_start_date_sk <= i.inv_date_sk
                  AND p.p_end_date_sk >= i.inv_date_sk
            ), 0)
    ) AS weighted_promo_cost
FROM inventory i
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'CA'
  AND i.inv_date_sk BETWEEN 2450000 AND 2459999
GROUP BY
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state
ORDER BY total_qty DESC
LIMIT 10
