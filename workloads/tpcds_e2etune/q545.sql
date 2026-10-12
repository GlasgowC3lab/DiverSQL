WITH refunded_addr AS (
    SELECT ca_address_sk, ca_state AS refunded_state
    FROM customer_address
),
returning_addr AS (
    SELECT ca_address_sk, ca_state AS returning_state
    FROM customer_address
),
agg AS (
    SELECT
        ra.refunded_state,
        ta.returning_state,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_store_credit) AS avg_store_credit,
        SUM(cr.cr_fee) AS total_fee
    FROM catalog_returns cr
    JOIN refunded_addr ra ON cr.cr_refunded_addr_sk = ra.ca_address_sk
    JOIN returning_addr ta ON cr.cr_returning_addr_sk = ta.ca_address_sk
    WHERE cr.cr_store_credit > 50
      AND cr.cr_return_tax > 0
      AND cr.cr_returned_date_sk = 2451132
      AND cr.cr_returning_cdemo_sk IN (479100, 746682, 498439)
    GROUP BY ra.refunded_state, ta.returning_state
    HAVING COUNT(*) >= 5
)
SELECT
    refunded_state,
    returning_state,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_store_credit,
    total_fee,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
