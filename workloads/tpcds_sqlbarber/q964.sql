SELECT
    cc.cc_state,
    cc.cc_name,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM
    catalog_returns cr
JOIN
    call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE
    cr.cr_returned_date_sk >= 2450928
    AND cr.cr_returned_date_sk <= 2451008
GROUP BY
    cc.cc_state,
    cc.cc_name
ORDER BY
    total_return_amount DESC
LIMIT 2451045
