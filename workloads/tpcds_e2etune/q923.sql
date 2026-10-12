SELECT cc.cc_state,
       sm.sm_type,
       w.w_city,
       COUNT(*) AS num_returns,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_return_tax) AS total_return_tax,
       AVG(cr.cr_return_quantity) AS avg_quantity
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE cc.cc_state IN ('TN', 'LA')
  AND sm.sm_type = 'AIR'
  AND cr.cr_return_amount > 100
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
GROUP BY cc.cc_state, sm.sm_type, w.w_city
HAVING SUM(cr.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 50
