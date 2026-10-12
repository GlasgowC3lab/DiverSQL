WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_email_address,
        c_current_hdemo_sk
    FROM tpcds.customer
    WHERE regexp_like(c_email_address, '^.*@example\\.com$')
)
SELECT
    CONCAT('Band ', CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_band_label,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT fc.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM filtered_customers fc
JOIN tpcds.store_sales ss
    ON ss.ss_customer_sk = fc.c_customer_sk
JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_buy_potential LIKE '%5000%'
GROUP BY
    CONCAT('Band ', CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)),
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_net_paid DESC
LIMIT 100
