SELECT
    cc.cc_call_center_id,
    cc.cc_division_name,
    sm.sm_type AS ship_mode_type,
    date_add('day', cr.cr_returned_date_sk, DATE '1970-01-01') AS return_date,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_fee) AS total_fees,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    RANK() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cr.cr_return_amount) DESC) AS return_amount_rank
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = cr.cr_returned_date_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE cc.cc_division = 3
  AND sm.sm_type = 'AIR'
  AND inv.inv_quantity_on_hand > 0
  AND cd_refunded.cd_gender = 'F'
  AND cd_returning.cd_marital_status = 'M'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_division_name,
    sm.sm_type,
    cr.cr_returned_date_sk
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
