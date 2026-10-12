WITH base_returns AS (
  SELECT
    cr.cr_call_center_sk,
    cr.cr_ship_mode_sk,
    cr.cr_reason_sk,
    cr.cr_return_amt_inc_tax,
    cr.cr_return_quantity,
    cr.cr_returning_customer_sk,
    cr.cr_refunded_cash,
    CASE WHEN wp.wp_web_page_sk IS NOT NULL THEN 1 ELSE 0 END AS has_web_page
  FROM catalog_returns cr
  JOIN customer rcust
    ON cr.cr_returning_customer_sk = rcust.c_customer_sk
  LEFT JOIN web_page wp
    ON rcust.c_customer_sk = wp.wp_customer_sk
),
aggregated AS (
  SELECT
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode,
    r.r_reason_desc AS return_reason,
    COUNT(*) AS total_returns,
    SUM(cr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(cr_refunded_cash) AS total_refunded_cash,
    AVG(cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT br.cr_returning_customer_sk) AS distinct_returning_customers,
    SUM(has_web_page) AS returns_with_web_page,
    ROUND(100.0 * SUM(has_web_page) / COUNT(*), 2) AS pct_returns_with_web_page
  FROM base_returns br
  JOIN call_center cc
    ON br.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON br.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r
    ON br.cr_reason_sk = r.r_reason_sk
  WHERE cc.cc_hours LIKE '8AM%'
    AND cc.cc_zip IN ('38828', '74536', '33451')
    AND sm.sm_type IN ('AIR', 'RAIL')
  GROUP BY
    cc.cc_name,
    sm.sm_type,
    r.r_reason_desc
  HAVING COUNT(*) >= 10
)
SELECT
  call_center_name,
  ship_mode,
  return_reason,
  total_returns,
  total_return_amount_inc_tax,
  total_refunded_cash,
  avg_return_quantity,
  distinct_returning_customers,
  returns_with_web_page,
  pct_returns_with_web_page,
  RANK() OVER (PARTITION BY ship_mode ORDER BY total_return_amount_inc_tax DESC) AS ship_mode_rank
FROM aggregated
ORDER BY total_return_amount_inc_tax DESC
LIMIT 100
