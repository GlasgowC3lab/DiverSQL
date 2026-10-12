SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_ret.d_year,
    d_ret.d_quarter_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    COUNT(DISTINCT s.s_store_id) AS stores_closed_on_return_date,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_cc_closed.d_date) AS call_center_closed_date
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_ret.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    d_ret.d_year,
    d_ret.d_quarter_name
HAVING
    SUM(cr.cr_return_amount) > 10000
ORDER BY
    total_net_loss DESC
LIMIT 10
