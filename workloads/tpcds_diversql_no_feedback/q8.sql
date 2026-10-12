WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM
        customer c
    WHERE
        regexp_like(c.c_email_address, '\\.edu$')
        AND c.c_first_name LIKE 'M%'
        AND c.c_customer_sk NOT IN (
            SELECT wr.wr_refunded_customer_sk
            FROM web_returns wr
            WHERE wr.wr_return_amt > 1000
        )
)
SELECT
    fc.c_customer_sk,
    fc.full_name,
    fc.c_email_address,
    fc.email_domain,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM
    filtered_customers fc
JOIN
    store_sales ss
    ON ss.ss_customer_sk = fc.c_customer_sk
GROUP BY
    fc.c_customer_sk,
    fc.full_name,
    fc.c_email_address,
    fc.email_domain
ORDER BY
    total_net_paid DESC
LIMIT 100
