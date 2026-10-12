SELECT
    w.w_warehouse_name AS warehouse_name,
    w.w_state AS warehouse_state,
    sm.sm_type AS ship_mode,
    d.d_year,
    d.d_month_seq AS month_seq,
    COUNT(*) AS total_returns,
    SUM(r.cr_return_amount) AS total_return_amount,
    AVG(r.cr_return_tax) AS avg_return_tax,
    SUM(r.cr_net_loss) AS total_net_loss,
    COALESCE(MAX(i.total_qty_on_hand), 0) AS total_inventory_on_day,
    COUNT(DISTINCT CASE WHEN p.p_promo_sk IS NOT NULL THEN r.cr_order_number END) AS promo_affected_returns
FROM catalog_returns r
JOIN date_dim d
    ON r.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON r.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON r.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p
    ON r.cr_item_sk = p.p_item_sk
    AND r.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
LEFT JOIN (
    SELECT inv_warehouse_sk, inv_date_sk, SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
) i
    ON r.cr_warehouse_sk = i.inv_warehouse_sk
    AND r.cr_returned_date_sk = i.inv_date_sk
WHERE r.cr_reason_sk IN (51, 62)
  AND r.cr_warehouse_sk IN (5, 7, 10)
  AND r.cr_return_amount > 100
GROUP BY
    w.w_warehouse_name,
    w.w_state,
    sm.sm_type,
    d.d_year,
    d.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
