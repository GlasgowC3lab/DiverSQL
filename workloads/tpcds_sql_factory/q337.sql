WITH customer_returns AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_birth_year,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_return_amount,
    total_net_loss,
    total_refunded_cash,
    CASE WHEN total_return_amount > 1000 THEN 'High Value' ELSE 'Regular' END AS customer_category,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    DENSE_RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_return_amount DESC) AS income_band_return_rank
FROM customer_returns
ORDER BY return_amount_rank
LIMIT 100
