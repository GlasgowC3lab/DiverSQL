WITH agg AS (
    SELECT
        c.c_birth_year,
        c.c_preferred_cust_flag,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_net_loss) / NULLIF(COUNT(*),0) AS avg_net_loss
    FROM
        customer c
    JOIN
        store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE
        c.c_preferred_cust_flag = 'Y'
        AND c.c_last_review_date >= 2452400
        AND c.c_birth_month IN (1,2,3)
        AND c.c_current_addr_sk IN (2715158, 1384401)
        AND sr.sr_return_quantity > 1
        AND sr.sr_return_amt > 50
    GROUP BY
        c.c_birth_year,
        c.c_preferred_cust_flag
    HAVING
        SUM(sr.sr_return_amt) > 1000
)
SELECT
    a.c_birth_year,
    a.c_preferred_cust_flag,
    a.num_customers,
    a.total_return_amt,
    a.avg_return_amt,
    a.total_net_loss,
    a.avg_net_loss,
    CASE
        WHEN a.total_net_loss > 5000 THEN 'High'
        ELSE 'Low'
    END AS net_loss_category,
    RANK() OVER (ORDER BY a.total_return_amt DESC) AS return_amt_rank
FROM
    agg a
ORDER BY
    a.total_return_amt DESC
LIMIT 50
