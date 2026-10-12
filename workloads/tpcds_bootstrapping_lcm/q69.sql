SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_city,
  w.w_warehouse_name,
  s.s_store_name,
  d_return.d_year,
  d_return.d_month_seq,
  d_cc_closed.d_date AS call_center_closed_date,
  d_cc_open.d_date   AS call_center_open_date,
  d_store.d_date     AS store_closed_date,
  SUM(cr.cr_net_loss)          AS total_net_loss,
  SUM(cr.cr_return_amount)     AS total_return_amount,
  SUM(cr.cr_return_quantity)   AS total_return_quantity,
  COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
  AVG(cc.cc_tax_percentage)    AS avg_cc_tax_pct,
  AVG(s.s_tax_percentage)      AS avg_store_tax_pct,
  MIN(d_return.d_date)         AS first_return_date,
  MAX(d_return.d_date)         AS last_return_date
FROM catalog_returns cr
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_store
  ON s.s_closed_date_sk = d_store.d_date_sk
GROUP BY
  cc.cc_call_center_id,
  cc.cc_name,
  cc.cc_city,
  w.w_warehouse_name,
  s.s_store_name,
  d_return.d_year,
  d_return.d_month_seq,
  d_cc_closed.d_date,
  d_cc_open.d_date,
  d_store.d_date
ORDER BY total_net_loss DESC
LIMIT 100
