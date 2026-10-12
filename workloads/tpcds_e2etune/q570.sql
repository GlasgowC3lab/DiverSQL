SELECT
    w_warehouse_name,
    w_city,
    i_category,
    total_qty,
    total_inventory_value,
    total_promo_cost,
    promo_cost_ratio,
    RANK() OVER (PARTITION BY i_category ORDER BY promo_cost_ratio DESC) AS promo_cost_rank
FROM (
    SELECT
        w.w_warehouse_name AS w_warehouse_name,
        w.w_city AS w_city,
        it.i_category AS i_category,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        SUM(i.inv_quantity_on_hand * it.i_current_price) AS total_inventory_value,
        COALESCE(SUM(p.p_cost), 0) AS total_promo_cost,
        CASE
            WHEN SUM(i.inv_quantity_on_hand * it.i_current_price) = 0 THEN 0
            ELSE COALESCE(SUM(p.p_cost), 0) / SUM(i.inv_quantity_on_hand * it.i_current_price)
        END AS promo_cost_ratio
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN item it ON i.inv_item_sk = it.i_item_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = it.i_item_sk
        AND p.p_start_date_sk <= d.d_date_sk
        AND p.p_end_date_sk >= d.d_date_sk
    WHERE d.d_year = 2022
      AND d.d_moy = 7
    GROUP BY w.w_warehouse_name, w.w_city, it.i_category
) sub
ORDER BY promo_cost_ratio DESC
LIMIT 100
