WITH cust_refunds AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS num_returns,
        MIN(s.s_store_id) AS primary_store_id
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address,
             hd.hd_buy_potential, hd.hd_income_band_sk
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_email_address,
    hd_buy_potential,
    hd_income_band_sk,
    primary_store_id,
    total_refunded_cash,
    total_return_amount,
    num_returns,
    CASE
        WHEN total_refunded_cash >= 10000 THEN 'Platinum'
        WHEN total_refunded_cash >= 5000 THEN 'Gold'
        WHEN total_refunded_cash >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS refund_tier,
    DENSE_RANK() OVER (ORDER BY total_refunded_cash DESC) AS refund_rank
FROM cust_refunds
WHERE total_refunded_cash > 0
ORDER BY refund_rank
LIMIT 20
