WITH agg AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_city,
        s.s_floor_space,
        s.s_tax_percentage,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
        SUM(cr.cr_return_amount) / NULLIF(s.s_floor_space, 0) AS return_amount_per_floor_space,
        SUM(cr.cr_return_amount * (1 + s.s_tax_percentage / 100)) AS tax_adjusted_return_amount
    FROM catalog_returns cr
    JOIN inventory inv
        ON cr.cr_item_sk = inv.inv_item_sk
       AND cr.cr_warehouse_sk = inv.inv_warehouse_sk
       AND cr.cr_returned_date_sk = inv.inv_date_sk
    JOIN store s
        ON inv.inv_warehouse_sk = s.s_store_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_order_number IN (2634398, 2634404)
      AND s.s_state = 'CA'
    GROUP BY s.s_store_sk, s.s_state, s.s_city, s.s_floor_space, s.s_tax_percentage
    HAVING SUM(cr.cr_return_quantity) > 0
)
SELECT
    s_store_sk,
    s_state,
    s_city,
    total_return_amount,
    total_return_quantity,
    avg_return_amount,
    total_inventory_quantity,
    CASE WHEN total_inventory_quantity = 0 THEN 0
         ELSE total_return_quantity / total_inventory_quantity END AS return_rate,
    return_amount_per_floor_space,
    tax_adjusted_return_amount,
    RANK() OVER (ORDER BY CASE WHEN total_inventory_quantity = 0 THEN 0
                               ELSE total_return_quantity / total_inventory_quantity END DESC) AS return_rate_rank
FROM agg
ORDER BY return_rate_rank
LIMIT 10
