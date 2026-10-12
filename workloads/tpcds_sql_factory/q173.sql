WITH combined_customer AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        d.d_year AS return_year,
        cr.cr_net_loss AS net_loss,
        ca.ca_state AS state,
        'catalog' AS source,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 0
    UNION ALL
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year AS return_year,
        sr.sr_net_loss AS net_loss,
        ca.ca_state AS state,
        'store' AS source,
        sr.sr_return_amt AS return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 0
),
customer_yearly AS (
    SELECT
        customer_sk,
        return_year,
        SUM(net_loss) AS yearly_net_loss,
        AVG(return_amount) AS avg_return_amount
    FROM combined_customer
    GROUP BY customer_sk, return_year
),
ranked_yearly AS (
    SELECT
        cy.customer_sk,
        cy.return_year,
        cy.yearly_net_loss,
        cy.avg_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cy.customer_sk ORDER BY cy.yearly_net_loss DESC) AS year_rank
    FROM customer_yearly cy
)
SELECT
    ry.customer_sk,
    ry.return_year,
    ry.yearly_net_loss,
    ry.avg_return_amount,
    ry.year_rank,
    CASE WHEN ry.yearly_net_loss > 15000 THEN 'High' WHEN ry.yearly_net_loss > 5000 THEN 'Medium' ELSE 'Low' END AS loss_category
FROM ranked_yearly ry
WHERE ry.return_year >= 2020
ORDER BY ry.yearly_net_loss DESC
LIMIT 100
