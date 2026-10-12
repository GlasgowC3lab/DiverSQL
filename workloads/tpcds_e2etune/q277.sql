SELECT
    department,
    catalog_number,
    distinct_items,
    total_quantity,
    avg_quantity,
    RANK() OVER (ORDER BY total_quantity DESC) AS dept_rank
FROM (
    SELECT
        cp.cp_department AS department,
        cp.cp_catalog_number AS catalog_number,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity
    FROM catalog_page cp
    JOIN inventory inv
        ON inv.inv_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'monthly'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY cp.cp_department, cp.cp_catalog_number
    HAVING SUM(inv.inv_quantity_on_hand) > 1000
) t
ORDER BY total_quantity DESC
LIMIT 50
