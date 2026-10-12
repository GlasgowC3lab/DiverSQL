WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        w.w_warehouse_id,
        w.w_state,
        r.r_reason_desc,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returning_customer_sk,
        cr.cr_item_sk,
        i.inv_quantity_on_hand,
        CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
        li.total_qty_item
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT sum(i2.inv_quantity_on_hand) AS total_qty_item
        FROM inventory i2
        WHERE i2.inv_item_sk = i.inv_item_sk
    ) li ON true
    WHERE cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND cr.cr_return_quantity > 0
      AND i.inv_quantity_on_hand > 0
)
SELECT
    cc_call_center_id,
    w_warehouse_id,
    r_reason_desc,
    risk_level,
    SUM(cr_return_quantity) AS total_return_qty,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr_returning_customer_sk) AS distinct_customers,
    COUNT(DISTINCT cr_item_sk) AS distinct_items,
    SUM(total_qty_item) AS total_item_qty_all_warehouses,
    CASE WHEN SUM(cr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY SUM(cr_net_loss) DESC) AS warehouse_loss_rank
FROM base
CROSS JOIN UNNEST(ARRAY['High','Medium','Low']) AS t(risk_level)
GROUP BY ROLLUP (cc_call_center_id, w_warehouse_id, r_reason_desc, risk_level)
HAVING SUM(cr_return_quantity) > 10
ORDER BY total_net_loss DESC
LIMIT 100
