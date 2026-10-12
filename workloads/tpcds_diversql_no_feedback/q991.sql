WITH refunded AS (
    SELECT
        c.c_birth_country,
        cr.cr_store_credit,
        SUM(cr.cr_return_amount) AS total_return,
        AVG(lr.return_rate) AS avg_return_rate
    FROM
        catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        CROSS JOIN LATERAL (
            SELECT CASE WHEN cr.cr_return_amt_inc_tax = 0 THEN NULL
                        ELSE cr.cr_return_amount / cr.cr_return_amt_inc_tax END AS return_rate
        ) AS lr
    WHERE
        cr.cr_return_tax > 1.00
        AND c.c_birth_country IN ('SWITZERLAND', 'KOREA')
    GROUP BY CUBE (c.c_birth_country, cr.cr_store_credit)
),
returning AS (
    SELECT
        c.c_birth_country,
        cr.cr_store_credit,
        SUM(cr.cr_return_amount) AS total_return,
        AVG(lr.return_rate) AS avg_return_rate
    FROM
        catalog_returns cr
        JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
        CROSS JOIN LATERAL (
            SELECT CASE WHEN cr.cr_return_amt_inc_tax = 0 THEN NULL
                        ELSE cr.cr_return_amount / cr.cr_return_amt_inc_tax END AS return_rate
        ) AS lr
    WHERE
        cr.cr_return_ship_cost < 500
        AND c.c_birth_day = 14
    GROUP BY CUBE (c.c_birth_country, cr.cr_store_credit)
)
SELECT
    u.c_birth_country,
    u.cr_store_credit,
    u.total_return,
    u.avg_return_rate,
    LAG(u.total_return) OVER (PARTITION BY u.c_birth_country ORDER BY u.cr_store_credit) AS prev_total_return
FROM (
    SELECT * FROM refunded
    UNION ALL
    SELECT * FROM returning
) u
ORDER BY u.c_birth_country, u.cr_store_credit
LIMIT 100
