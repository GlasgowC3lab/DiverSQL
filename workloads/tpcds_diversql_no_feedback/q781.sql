WITH intersect_addresses AS (
    SELECT cr.cr_refunded_addr_sk AS addr_sk
    FROM catalog_returns cr
    WHERE cr.cr_store_credit > 100
    INTERSECT
    SELECT ca.ca_address_sk
    FROM customer_address ca
    WHERE ca.ca_state = 'CA'
)
SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    ca.ca_state,
    ca.ca_city,
    t.t_hour,
    t.t_shift,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cr.cr_net_loss DESC) AS rn_state
FROM catalog_returns cr
INNER JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
INNER JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
INNER JOIN intersect_addresses ia
    ON cr.cr_refunded_addr_sk = ia.addr_sk
WHERE cr.cr_warehouse_sk IN (6, 8, 9)
  AND ca.ca_city LIKE '%College%'
  AND t.t_shift = 'first'
  AND cr.cr_return_amount > 50
ORDER BY rn_state, cr.cr_net_loss DESC
LIMIT 100
