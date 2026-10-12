WITH filtered_calls AS (
    SELECT cc.cc_call_center_sk
    FROM call_center cc
    WHERE cc.cc_employees > 200
    INTERSECT
    SELECT cr.cr_call_center_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 5000
)
SELECT
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr.cr_order_number) AS unique_orders,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
  AND cp.cp_department IN ('Books', 'Electronics', 'Home')
  AND sm.sm_type = 'OVERNIGHT'
  AND cr.cr_return_amount > 100.00
  AND cr.cr_return_quantity BETWEEN 1 AND 5
  AND cd.cd_purchase_estimate > 5000
  AND EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = cr.cr_refunded_cdemo_sk
          AND cd2.cd_dep_college_count >= 4
      )
  AND cr.cr_call_center_sk IN (SELECT cc_call_center_sk FROM filtered_calls)
GROUP BY cc.cc_name, cp.cp_department, sm.sm_type
ORDER BY total_return_amount DESC
LIMIT 100
