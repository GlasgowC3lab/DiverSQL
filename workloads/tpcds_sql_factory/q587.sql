WITH customer_return_stats AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, hd.hd_income_band_sk
), ranked_customers AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY avg_return_amount DESC) AS avg_amount_rank
    FROM customer_return_stats
    WHERE total_returns >= 10
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_income_band_sk,
    total_returns,
    total_return_amount,
    avg_return_amount,
    CASE WHEN avg_return_amount > 1000 THEN 'VIP' ELSE 'Regular' END AS customer_tier,
    avg_amount_rank
FROM ranked_customers
WHERE avg_amount_rank <= 5
ORDER BY avg_amount_rank
