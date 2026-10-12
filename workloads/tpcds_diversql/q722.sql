SELECT cr.cr_returned_date_sk,
       cr.cr_return_amount,
       sm.sm_carrier,
       sm.sm_type
FROM tpcds.catalog_returns AS cr
JOIN tpcds.ship_mode AS sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_return_amount > 150.00
  AND sm.sm_carrier = 'USPS'
ORDER BY cr.cr_return_amount DESC
LIMIT 50
