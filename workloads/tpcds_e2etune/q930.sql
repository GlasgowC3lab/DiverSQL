SELECT
  cc.cc_name AS call_center_name,
  s.s_store_name AS store_name,
  s.s_state,
  dr.d_year,
  dr.d_month_seq,
  SUM(sr.sr_return_amt) AS total_return_amount,
  SUM(sr.sr_return_quantity) AS total_return_quantity,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
  COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_promo_pages,
  SUM(sr.sr_return_amt) / NULLIF(SUM(inv.inv_quantity_on_hand), 0) AS return_to_inventory_ratio
FROM store_returns sr
JOIN date_dim dr
  ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN call_center cc
  ON dr.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
JOIN date_dim d_open
  ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
  ON cc.cc_closed_date_sk = d_close.d_date_sk
JOIN inventory inv
  ON inv.inv_date_sk = dr.d_date_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = dr.d_date_sk
WHERE cc.cc_class = 'large'
  AND s.s_state = 'CA'
  AND cp.cp_type = 'Promotion'
  AND dr.d_year BETWEEN 2001 AND 2002
GROUP BY cc.cc_name, s.s_store_name, s.s_state, dr.d_year, dr.d_month_seq
HAVING SUM(sr.sr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
