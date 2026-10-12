WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_amt
    FROM catalog_returns
)
SELECT order_num,
       return_amount,
       city,
       warehouse_id
FROM (
    SELECT
        cr.cr_order_number AS order_num,
        cr.cr_return_amount AS return_amount,
        ca_refunded.ca_city AS city,
        w.w_warehouse_id AS warehouse_id
    FROM catalog_returns AS cr
    JOIN customer_address AS ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN warehouse AS w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE ca_refunded.ca_city = 'New York'
      AND w.w_street_name = 'Hickory Laurel'
      AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)

    UNION ALL

    SELECT
        cr.cr_order_number AS order_num,
        cr.cr_return_amount AS return_amount,
        ca_returning.ca_city AS city,
        w.w_warehouse_id AS warehouse_id
    FROM catalog_returns AS cr
    JOIN customer_address AS ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN warehouse AS w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE ca_returning.ca_city = 'Chicago'
      AND w.w_state = 'CA'
      AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
) AS combined
ORDER BY return_amount DESC, order_num ASC
LIMIT 100
