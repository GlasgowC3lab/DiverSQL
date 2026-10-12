WITH low_income AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_return_amt) AS total_return_amt,
        (
            SELECT SUM(sr2.sr_fee)
            FROM store_returns sr2
            WHERE sr2.sr_hdemo_sk = hd.hd_demo_sk
        ) AS total_fee_for_demo
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 100000
    GROUP BY hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
high_income AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_return_amt) AS total_return_amt,
        (
            SELECT SUM(sr2.sr_fee)
            FROM store_returns sr2
            WHERE sr2.sr_hdemo_sk = hd.hd_demo_sk
        ) AS total_fee_for_demo
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound > 100000
    GROUP BY hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT *
FROM (
    SELECT * FROM low_income
    UNION ALL
    SELECT * FROM high_income
) AS combined
ORDER BY total_return_amt DESC
OFFSET 0
LIMIT 100
