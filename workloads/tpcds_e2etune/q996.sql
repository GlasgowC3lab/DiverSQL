WITH refunded_address AS (
    SELECT ca_address_sk, ca_state, ca_country, ca_zip
    FROM customer_address
),
returning_address AS (
    SELECT ca_address_sk, ca_state AS ret_state, ca_country AS ret_country, ca_zip AS ret_zip
    FROM customer_address
),
agg AS (
    SELECT
        ra.ca_state AS refunded_state,
        rra.ret_state AS returning_state,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    JOIN refunded_address ra ON cr.cr_refunded_addr_sk = ra.ca_address_sk
    JOIN returning_address rra ON cr.cr_returning_addr_sk = rra.ca_address_sk
    WHERE cr.cr_return_quantity > 5
      AND cr.cr_call_center_sk IN (19, 40)
      AND ra.ca_country = 'United States'
    GROUP BY ra.ca_state, rra.ret_state
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    refunded_state,
    returning_state,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
