SELECT
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    cc.cc_name AS call_center_name,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    CAST(SUM(i.inv_quantity_on_hand) AS double) / NULLIF(SUM(cr.cr_return_quantity), 0) AS inventory_per_return_qty
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cc.cc_closed_date_sk = d.d_date_sk
    AND cc.cc_open_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    cc.cc_name,
    d.d_year,
    d.d_month_seq
HAVING SUM(cr.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 50
