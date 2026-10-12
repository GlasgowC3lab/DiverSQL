WITH agg AS (
  SELECT
    cc.cc_name AS call_center_name,
    r.r_reason_desc AS return_reason,
    sm.sm_carrier AS carrier,
    ca_ref.ca_state AS refunded_state,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_tax,
    SUM(cr.cr_return_quantity) AS total_quantity,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
    AND cc.cc_division = 3
    AND sm.sm_type = 'Standard'
  GROUP BY
    cc.cc_name,
    r.r_reason_desc,
    sm.sm_carrier,
    ca_ref.ca_state
  HAVING COUNT(*) > 5
)
SELECT
  call_center_name,
  return_reason,
  carrier,
  refunded_state,
  num_returns,
  total_return_amount,
  total_tax,
  total_quantity,
  avg_return_amount,
  distinct_returning_customers,
  RANK() OVER (PARTITION BY call_center_name ORDER BY total_return_amount DESC) AS reason_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
