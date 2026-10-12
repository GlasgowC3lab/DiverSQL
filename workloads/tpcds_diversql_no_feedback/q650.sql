WITH union_data AS (
  SELECT
    cc.cc_call_center_id,
    cr.cr_return_amount AS return_amount,
    d.d_year,
    hd.hd_buy_potential,
    sm.sm_type,
    cust.c_first_name,
    cust.c_last_name,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cr.cr_return_amount DESC) AS rn_return_amount
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
  WHERE d.d_year = 2001
    AND hd.hd_buy_potential = '1001-5000'
    AND sm.sm_type = 'AIR'
  UNION DISTINCT
  SELECT
    cc.cc_call_center_id,
    cr.cr_return_amount AS return_amount,
    d.d_year,
    hd.hd_buy_potential,
    sm.sm_type,
    cust.c_first_name,
    cust.c_last_name,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cr.cr_return_amount DESC) AS rn_return_amount
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
  WHERE d.d_year = 2002
    AND hd.hd_vehicle_count >= 2
    AND sm.sm_carrier = 'UPS'
)
SELECT
  ud.cc_call_center_id,
  ud.d_year,
  ud.hd_buy_potential,
  ud.sm_type,
  ud.c_first_name,
  ud.c_last_name,
  ud.return_amount,
  ud.rn_return_amount,
  RANK() OVER (PARTITION BY ud.d_year ORDER BY ud.return_amount DESC) AS year_rank,
  CASE WHEN ud.rn_return_amount = 1 THEN 'Top Return' ELSE 'Other' END AS return_category,
  sd.sm_type AS small_dim_type,
  cs.dummy
FROM union_data ud
CROSS JOIN (SELECT DISTINCT sm_type FROM ship_mode WHERE sm_type IN ('AIR','GROUND')) sd
CROSS JOIN (VALUES 1) AS cs(dummy)
ORDER BY year_rank ASC, ud.rn_return_amount ASC
LIMIT 100
