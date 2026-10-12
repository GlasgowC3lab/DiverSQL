SELECT
    sub.cr_returned_date_sk,
    sub.total_return_amount,
    sub.return_count,
    c.c_customer_id,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450957 AND 2450953
    GROUP BY
        cr.cr_returned_date_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk
    HAVING SUM(cr.cr_return_amount) > 1108.40
) sub
JOIN customer c
    ON sub.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON sub.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound > 100000
