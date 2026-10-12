SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    hd.hd_income_band_sk,
    (cr.cr_return_amount * 1.1) AS adjusted_return_amount,
    (cr.cr_return_quantity + hd.hd_vehicle_count) AS total_quantity_plus_vehicles,
    CASE
        WHEN cr.cr_return_amount > 1440.72 THEN 'LargeReturn'
        ELSE 'SmallReturn'
    END AS return_size_category,
    CASE
        WHEN hd.hd_buy_potential = 'Unknown        ' THEN 'PotentialHigh'
        WHEN hd.hd_buy_potential = '0-500          ' THEN 'PotentialMedium'
        ELSE 'PotentialLow'
    END AS buy_potential_category,
    (cr.cr_return_amount - cr.cr_return_tax) AS net_amount_excluding_tax
FROM catalog_returns cr
JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_returned_date_sk = 2450957
  AND hd.hd_income_band_sk = 19
