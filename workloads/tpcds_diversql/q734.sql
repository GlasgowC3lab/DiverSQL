WITH
full_item_inventory AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        itm.i_product_name,
        wh.w_warehouse_name
    FROM inventory inv
    FULL OUTER JOIN item itm
        ON inv.inv_item_sk = itm.i_item_sk
    LEFT JOIN warehouse wh
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
),
sampled_promotions AS (
    SELECT p.p_promo_sk, p.p_item_sk, p.p_discount_active
    FROM promotion p
    TABLESAMPLE BERNOULLI (5)
),
item_not_promoted AS (
    SELECT DISTINCT itm.i_item_sk
    FROM item itm
    EXCEPT
    SELECT DISTINCT p.p_item_sk
    FROM promotion p
)

SELECT *
FROM (
    SELECT
        sm.sm_type AS ship_mode_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CAST(0 AS integer) AS total_quantity_on_hand,
        r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 500
    GROUP BY sm.sm_type, r.r_reason_desc

    UNION

    SELECT
        'INVENTORY' AS ship_mode_type,
        CAST(0.00 AS decimal(7,2)) AS total_return_amount,
        SUM(fi.inv_quantity_on_hand) AS total_quantity_on_hand,
        'N/A' AS reason_desc
    FROM full_item_inventory fi
    JOIN sampled_promotions sp
        ON fi.inv_item_sk = sp.p_item_sk
    WHERE fi.inv_quantity_on_hand > 0
      AND fi.inv_item_sk IN (SELECT i_item_sk FROM item_not_promoted)
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
