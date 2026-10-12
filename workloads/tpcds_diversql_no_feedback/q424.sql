WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_fee,
        w.w_warehouse_id,
        w.w_state,
        w.w_city,
        w.w_warehouse_name
    FROM catalog_returns cr
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 100.00
      AND cr.cr_return_quantity <= 5
      AND cr.cr_return_tax BETWEEN 0.00 AND 50.00
      AND cr.cr_fee < 20.00
      AND w.w_street_type = 'Road'
      AND w.w_suite_number = 'Suite 80'
      AND w.w_city = 'Lincoln'
      AND w.w_state = 'TX'
      AND cr.cr_reversed_charge > 200.00
      AND cr.cr_store_credit < 500.00
)
SELECT
    w_state,
    w_city,
    w_warehouse_name,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_count,
    MIN(cr_return_quantity) AS min_quantity,
    MAX(cr_fee) AS max_fee
FROM filtered
WHERE w_warehouse_id NOT IN (
    SELECT w_warehouse_id FROM warehouse WHERE w_state = 'CA'
)
GROUP BY CUBE (w_state, w_city, w_warehouse_name)
ORDER BY w_state ASC, w_city ASC, w_warehouse_name ASC, total_return_amount DESC
LIMIT 100
