SELECT cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_amt_inc_tax,
       cr.cr_return_quantity * cr.cr_return_amount AS quantity_amount_product,
       cr.cr_return_amount + cr.cr_return_tax AS amount_plus_tax,
       cr.cr_return_amt_inc_tax - cr.cr_return_tax AS net_amount_without_tax,
       CASE WHEN cr.cr_return_quantity > 47 THEN 'HighQty' ELSE 'LowQty' END AS qty_category,
       CASE WHEN w.w_state = 'SC' THEN 'TargetState' ELSE w.w_state END AS state_label,
       CASE WHEN cr.cr_return_amount > 407.60 THEN 'LargeReturn' ELSE 'SmallReturn' END AS return_size,
       w.w_warehouse_name || ' - ' || w.w_city AS warehouse_location
FROM catalog_returns cr
INNER JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_returned_date_sk = 2451034
  AND w.w_country = 'United States'
