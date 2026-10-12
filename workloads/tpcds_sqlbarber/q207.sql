SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_employees,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_amount * (1 + cc.cc_tax_percentage) AS amount_with_tax,
    CASE
        WHEN cc.cc_employees > 3709927 THEN 'Large'
        WHEN cc.cc_employees BETWEEN 3181926 AND 2372343 THEN 'Medium'
        ELSE 'Small'
    END AS employee_size,
    CASE
        WHEN cr.cr_return_quantity = 6 THEN 'SingleItem'
        ELSE 'MultipleItems'
    END AS return_type,
    CONCAT(cc.cc_name, ' - ', cc.cc_city) AS center_location,
    cc.cc_gmt_offset * 60 AS gmt_offset_minutes,
    cr.cr_return_amount - cr.cr_fee AS net_return_amount
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE cr.cr_return_amount > 23.17
