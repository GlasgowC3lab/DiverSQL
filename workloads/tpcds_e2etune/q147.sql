WITH inventory_agg AS (
    SELECT inv_item_sk AS item_sk,
           AVG(inv_quantity_on_hand) AS avg_qty_on_hand,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
),
returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_reason_sk AS reason_sk,
        i.i_category,
        i.i_category_id,
        i.i_item_id,
        i.i_class,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(cr.cr_fee) AS avg_fee
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_call_center_sk IN (19, 40)
      AND cr.cr_return_tax > 30
    GROUP BY cr.cr_item_sk, cr.cr_reason_sk,
             i.i_category, i.i_category_id, i.i_item_id, i.i_class,
             r.r_reason_desc
),
ranked AS (
    SELECT
        ra.*,
        ia.avg_qty_on_hand,
        ia.total_qty_on_hand,
        ROW_NUMBER() OVER (PARTITION BY ra.i_category ORDER BY ra.total_net_loss DESC) AS loss_rank
    FROM returns_agg ra
    JOIN inventory_agg ia ON ra.item_sk = ia.item_sk
)
SELECT
    i_category,
    i_category_id,
    i_item_id,
    i_class,
    r_reason_desc,
    total_net_loss,
    total_return_amount,
    total_return_qty,
    distinct_orders,
    avg_fee,
    avg_qty_on_hand,
    total_qty_on_hand,
    loss_rank
FROM ranked
WHERE loss_rank <= 5
ORDER BY i_category, loss_rank
