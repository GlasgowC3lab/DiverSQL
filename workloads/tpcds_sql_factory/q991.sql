WITH cust_agg AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        MIN(d.d_date) AS first_return_date,
        MAX(d.d_date) AS last_return_date,
        COUNT(DISTINCT s.s_store_id) AS distinct_stores
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.total_returns,
    c.total_return_amt,
    c.total_net_loss,
    c.avg_return_amt,
    c.first_return_date,
    c.last_return_date,
    c.distinct_stores,
    CASE
        WHEN c.total_return_amt > 5000 THEN 'Platinum'
        WHEN c.total_return_amt > 2000 THEN 'Gold'
        WHEN c.total_return_amt > 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS tier,
    DENSE_RANK() OVER (ORDER BY c.total_return_amt DESC) AS cust_return_rank
FROM cust_agg c
ORDER BY cust_return_rank
LIMIT 20
