SELECT
  cc.cc_name AS call_center_name,
  cc.cc_state AS state,
  p.p_promo_name AS promo_name,
  r.r_reason_desc AS return_reason,
  sm.sm_type AS ship_mode_type,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  SUM(cr.cr_net_loss) AS total_net_loss,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_quantity) AS avg_return_quantity,
  SUM(cr.cr_return_ship_cost) AS total_ship_cost
FROM
  catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN promotion p ON i.i_item_sk = p.p_item_sk AND p.p_discount_active = 'Y'
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
  cc.cc_state IN ('TN', 'LA')
  AND r.r_reason_desc LIKE '%damage%'
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450500
GROUP BY
  cc.cc_name,
  cc.cc_state,
  p.p_promo_name,
  r.r_reason_desc,
  sm.sm_type
HAVING
  SUM(cr.cr_net_loss) > 1000
ORDER BY
  total_net_loss DESC
LIMIT 100
