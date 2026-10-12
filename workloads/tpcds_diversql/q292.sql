WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    cp.cp_department,
    sm.sm_carrier,
    CASE WHEN sm.sm_type = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_category,
    COUNT(DISTINCT sr.cr_order_number) AS num_orders,
    SUM(sr.cr_return_amount) AS total_return_amount,
    AVG(sr.cr_return_tax) AS avg_return_tax,
    MIN(sr.cr_return_amount) AS min_return_amount,
    MAX(sr.cr_return_amount) AS max_return_amount
FROM sampled_returns sr
JOIN catalog_page cp
    ON sr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON sr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
    ON sr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE
    sm.sm_contract IN ('HVDFCcQ', 'I3uCelXtjP')
    AND ca.ca_suite_number = 'Suite 200'
    AND ca.ca_location_type = 'condo'
    AND sr.cr_return_tax > 30
    AND sr.cr_return_amount BETWEEN 100 AND 500
    AND sr.cr_return_amount > (
        SELECT MIN(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_return_tax > 70
    )
    AND sr.cr_order_number IN (
        SELECT cr1.cr_order_number FROM catalog_returns cr1 WHERE cr1.cr_return_amount > 200
        INTERSECT
        SELECT cr2.cr_order_number FROM catalog_returns cr2 WHERE cr2.cr_return_tax > 40
    )
GROUP BY
    cp.cp_department,
    sm.sm_carrier,
    CASE WHEN sm.sm_type = 'AIR' THEN 'Air' ELSE 'Other' END
ORDER BY total_return_amount DESC
LIMIT 100
