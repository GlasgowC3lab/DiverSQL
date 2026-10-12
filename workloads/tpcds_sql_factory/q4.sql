WITH combined_customer AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        d.d_date AS return_date,
        cr.cr_net_loss AS net_loss,
        ca.ca_state AS state,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_date AS return_date,
        sr.sr_net_loss AS net_loss,
        ca.ca_state AS state,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),
customer_totals AS (
    SELECT
        customer_sk,
        SUM(net_loss) AS total_net_loss
    FROM combined_customer
    GROUP BY customer_sk
),
customer_rank AS (
    SELECT
        ct.customer_sk,
        ct.total_net_loss,
        RANK() OVER (ORDER BY ct.total_net_loss DESC) AS loss_rank,
        CASE
            WHEN ct.total_net_loss > 20000 THEN 'Platinum'
            WHEN ct.total_net_loss > 10000 THEN 'Gold'
            WHEN ct.total_net_loss > 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS tier
    FROM customer_totals ct
)
SELECT
    cc.customer_sk,
    cc.state,
    cc.return_date,
    cc.net_loss,
    SUM(cc.net_loss) OVER (PARTITION BY cc.customer_sk ORDER BY cc.return_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
    cr.loss_rank,
    cr.tier
FROM combined_customer cc
JOIN customer_rank cr ON cc.customer_sk = cr.customer_sk
WHERE cc.return_date >= DATE '2023-01-01'
ORDER BY cr.loss_rank, cc.return_date
LIMIT 200
