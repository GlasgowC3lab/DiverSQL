WITH combined_customer AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        d.d_date AS return_date,
        cr.cr_net_loss AS net_loss,
        ca.ca_state AS state,
        'catalog' AS source,
        cr.cr_return_quantity AS qty,
        cr.cr_return_amount AS amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_quantity > 0
    UNION ALL
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_date AS return_date,
        sr.sr_net_loss AS net_loss,
        ca.ca_state AS state,
        'store' AS source,
        sr.sr_return_quantity AS qty,
        sr.sr_return_amt AS amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
),
agg_by_state AS (
    SELECT
        state,
        source,
        SUM(net_loss) AS state_net_loss,
        SUM(qty) AS total_qty,
        AVG(amount) AS avg_amount
    FROM combined_customer
    GROUP BY state, source
)
SELECT
    a.state,
    a.source,
    a.state_net_loss,
    a.total_qty,
    a.avg_amount,
    RANK() OVER (PARTITION BY a.source ORDER BY a.state_net_loss DESC) AS state_rank,
    SUM(a.state_net_loss) OVER (PARTITION BY a.source) AS source_total_loss
FROM agg_by_state a
WHERE a.state IS NOT NULL
ORDER BY a.source, state_rank
LIMIT 80
