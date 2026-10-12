WITH combined AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_paid AS amount,
        CAST('sale' AS VARCHAR) AS transaction_type
    FROM
        tpcds.catalog_sales cs
        INNER JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        INNER JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        cc.cc_zip = '85804'
        AND p.p_promo_id = 'PROMO123'
    UNION ALL
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        cr.cr_refunded_cash AS amount,
        CAST('return' AS VARCHAR) AS transaction_type
    FROM
        tpcds.catalog_returns cr
        INNER JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        INNER JOIN tpcds.household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE
        cc.cc_state = 'CA'
        AND hd.hd_income_band_sk = 12
)
SELECT
    COUNT(DISTINCT customer_sk) AS distinct_customers,
    COUNT(DISTINCT transaction_type) AS distinct_transaction_types,
    SUM(DISTINCT amount) AS sum_distinct_amount
FROM combined
LIMIT 100
