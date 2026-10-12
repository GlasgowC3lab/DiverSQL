WITH wi AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM warehouse w
    FULL OUTER JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
)
SELECT
    wi.w_warehouse_name,
    wi.w_state,
    COALESCE(wi.inv_quantity_on_hand, 0) AS quantity_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS orders_sold,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_quantity) AS min_return_qty,
    MAX(cr.cr_return_quantity) AS max_return_qty
FROM wi
JOIN catalog_sales cs
    ON cs.cs_warehouse_sk = wi.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN reason r
    ON r.r_reason_sk = cr.cr_reason_sk
WHERE
    wi.inv_quantity_on_hand > 500
    AND sm.sm_ship_mode_id = 'AAAAAAAACAAAAAAA'
    AND r.r_reason_desc = 'Customer not satisfied'
    AND wi.w_state = 'CA'
    AND cs.cs_net_paid > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2)
GROUP BY
    wi.w_warehouse_name,
    wi.w_state,
    COALESCE(wi.inv_quantity_on_hand, 0)

UNION DISTINCT

SELECT
    wi.w_warehouse_name,
    wi.w_state,
    COALESCE(wi.inv_quantity_on_hand, 0) AS quantity_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS orders_sold,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_quantity) AS min_return_qty,
    MAX(cr.cr_return_quantity) AS max_return_qty
FROM wi
JOIN catalog_sales cs
    ON cs.cs_warehouse_sk = wi.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN reason r
    ON r.r_reason_sk = cr.cr_reason_sk
WHERE
    wi.inv_quantity_on_hand <= 500
    AND sm.sm_ship_mode_id = 'AAAAAAAANAAAAAAA'
    AND r.r_reason_desc = 'Damaged item'
    AND wi.w_state = 'NY'
    AND cs.cs_net_paid > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2)
GROUP BY
    wi.w_warehouse_name,
    wi.w_state,
    COALESCE(wi.inv_quantity_on_hand, 0)
ORDER BY total_net_paid DESC
