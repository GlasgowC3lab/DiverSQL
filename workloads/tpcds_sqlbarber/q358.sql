SELECT
    cr.cr_order_number,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_tax,
    (cr.cr_return_amount - cr.cr_return_tax) AS net_return_amount,
    (cr.cr_return_amount * 1.10) AS return_amount_with_tax,
    CASE
        WHEN cr.cr_return_quantity > 5 THEN 'Large'
        ELSE 'Small'
    END AS quantity_category,
    CASE
        WHEN cr.cr_return_amount > 100 THEN 'HighValue'
        WHEN cr.cr_return_amount > 50 THEN 'MediumValue'
        ELSE 'LowValue'
    END AS value_category,
    CASE sm.sm_type
        WHEN 'AIR' THEN cr.cr_return_amount * 0.9
        WHEN 'GROUND' THEN cr.cr_return_amount * 1.1
        ELSE cr.cr_return_amount
    END AS adjusted_return_amount,
    sm.sm_ship_mode_id,
    sm.sm_type,
    sm.sm_carrier
FROM catalog_returns cr
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_returned_date_sk = 2450969
  AND sm.sm_type = 'REGULAR                       '
