WITH promo_inventory AS (
    SELECT
        cp.cp_type,
        cp.cp_department,
        COUNT(DISTINCT p.p_promo_sk) AS promo_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM
        catalog_page cp
        JOIN promotion p
            ON p.p_start_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
        JOIN inventory inv
            ON inv.inv_item_sk = p.p_item_sk
            AND inv.inv_date_sk = p.p_start_date_sk
    WHERE
        cp.cp_type IN ('bi-annual', 'quarterly', 'monthly')
        AND p.p_discount_active = 'Y'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY
        cp.cp_type,
        cp.cp_department
    HAVING
        SUM(p.p_cost) > 1000
)
SELECT
    cp_type,
    cp_department,
    promo_cnt,
    total_promo_cost,
    avg_quantity_on_hand,
    RANK() OVER (ORDER BY total_promo_cost DESC) AS cost_rank
FROM promo_inventory
ORDER BY total_promo_cost DESC
LIMIT 10
