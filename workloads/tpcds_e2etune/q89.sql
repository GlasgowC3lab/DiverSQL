WITH reason_returns AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        hd_ret.hd_income_band_sk AS returning_income_band,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 200
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY r.r_reason_desc, hd_ret.hd_income_band_sk, hd_ref.hd_income_band_sk
    HAVING COUNT(*) > 10
)
SELECT
    reason_desc,
    returning_income_band,
    refunded_income_band,
    total_return_amount,
    total_refunded_cash,
    avg_return_quantity,
    return_cnt,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM reason_returns
ORDER BY total_return_amount DESC
LIMIT 100
