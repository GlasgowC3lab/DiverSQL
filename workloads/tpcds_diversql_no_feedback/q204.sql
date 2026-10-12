WITH refunded AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM tpcds.catalog_returns AS cr
    JOIN tpcds.customer AS c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address AS ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND cr.cr_returned_time_sk BETWEEN 16000 AND 40000
    GROUP BY GROUPING SETS ((cr.cr_order_number), ())
    HAVING SUM(cr.cr_return_amount) > 1000
),
returning AS (
    SELECT
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM tpcds.catalog_returns AS cr
    JOIN tpcds.customer AS c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address AS ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'NY'
      AND cr.cr_returned_time_sk BETWEEN 30000 AND 65000
    GROUP BY GROUPING SETS ((cr.cr_order_number), ())
    HAVING SUM(cr.cr_return_amount) > 1000
),
combined AS (
    SELECT cr_order_number, total_return_amount, total_return_quantity FROM refunded
    UNION ALL
    SELECT cr_order_number, total_return_amount, total_return_quantity FROM returning
)
SELECT
    c.cr_order_number,
    c.total_return_amount,
    c.total_return_quantity
FROM combined AS c
WHERE c.cr_order_number IS NOT NULL
  AND c.cr_order_number NOT IN (
        SELECT cr.cr_order_number
        FROM tpcds.catalog_returns AS cr
        WHERE cr.cr_return_amount > 5000
    )
ORDER BY c.total_return_amount DESC, c.cr_order_number
LIMIT 100
