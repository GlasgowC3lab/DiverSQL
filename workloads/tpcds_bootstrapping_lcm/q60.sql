SELECT
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_gmt_offset,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_net_loss,
    d.d_year,
    d.d_quarter_name,
    d.d_month_seq,
    i.inv_quantity_on_hand,
    i.inv_warehouse_sk,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
    AND cc.cc_closed_date_sk = d.d_date_sk
    AND cc.cc_open_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND cc.cc_employees > 100
  AND i.inv_quantity_on_hand > 0
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    cc.cc_gmt_offset,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_net_loss,
    d.d_year,
    d.d_quarter_name,
    d.d_month_seq,
    i.inv_quantity_on_hand,
    i.inv_warehouse_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY SUM(cr.cr_return_amount) DESC
LIMIT 100
