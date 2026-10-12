SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_fee,
    cr.cr_return_quantity,
    (cr.cr_return_amount + cr.cr_return_tax) AS total_before_fee,
    (cr.cr_return_amount + cr.cr_return_tax + cr.cr_fee) AS total_with_fee,
    CASE
        WHEN cr.cr_return_amount > 7.80 THEN cr.cr_return_amount * 0.9
        ELSE cr.cr_return_amount * 0.95
    END AS discounted_return_amount,
    CASE r.r_reason_desc
        WHEN 'Customer Not Satisfied' THEN 'CNS'
        WHEN 'Damaged' THEN 'DMG'
        ELSE 'OTH'
    END AS reason_code,
    cr.cr_return_quantity * cr.cr_return_amount AS total_return_value,
    (cr.cr_return_amount - cr.cr_fee) / NULLIF(cr.cr_return_quantity, 0) AS avg_net_per_item
FROM catalog_returns cr
INNER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_returned_date_sk BETWEEN 2451096 AND 2451132
