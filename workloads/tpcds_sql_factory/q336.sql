WITH ordered_returns AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        SUM(sr.sr_return_amt) OVER (
            PARTITION BY c.c_customer_id
            ORDER BY sr.sr_returned_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_return_amt,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), flagged AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY sr_returned_date_sk) AS rn
    FROM ordered_returns
    WHERE cumulative_return_amt >= 5000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_birth_year,
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    sr_returned_date_sk,
    cumulative_return_amt,
    CASE WHEN cumulative_return_amt >= 5000 THEN 'Churn Risk' ELSE 'Normal' END AS risk_category
FROM flagged
WHERE rn = 1
ORDER BY cumulative_return_amt DESC
LIMIT 20
