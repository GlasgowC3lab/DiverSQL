SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    d_closed.d_year AS closed_year,
    d_open.d_year AS open_year,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_number_employees,
    inv.inv_quantity_on_hand,
    inv.inv_warehouse_sk,
    wr.wr_return_amt,
    wr.wr_return_quantity,
    wr.wr_return_tax,
    d_wr.d_month_seq AS return_month_seq,
    d_inv.d_month_seq AS inventory_month_seq,
    s.s_state
FROM call_center cc
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_closed.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_closed.d_date_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
WHERE d_closed.d_year = 2020
  AND s.s_state = 'CA'
  AND inv.inv_quantity_on_hand > 0
  AND wr.wr_return_amt > 0
ORDER BY cc.cc_call_center_id, d_closed.d_date_sk
LIMIT 100
