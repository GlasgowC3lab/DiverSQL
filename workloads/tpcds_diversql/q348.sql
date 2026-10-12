WITH full_join AS (
        SELECT
            COALESCE(ss.ss_customer_sk, sr.sr_customer_sk) AS customer_sk,
            COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
            COALESCE(ss.ss_net_paid, sr.sr_return_amt) AS amount,
            CASE WHEN ss.ss_ticket_number IS NOT NULL THEN 'sale' ELSE 'return' END AS source
        FROM store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
    ),
    ranked AS (
        SELECT
            customer_sk,
            ticket_number,
            amount,
            source,
            row_number() OVER (PARTITION BY source ORDER BY amount DESC) AS rn
        FROM full_join
        WHERE amount IS NOT NULL
    ),
    top_k_sales AS (
        SELECT customer_sk, ticket_number, amount, source
        FROM ranked
        WHERE source = 'sale' AND rn <= 5
    ),
    top_k_returns AS (
        SELECT customer_sk, ticket_number, amount, source
        FROM ranked
        WHERE source = 'return' AND rn <= 5
    ),
    combined AS (
        SELECT customer_sk, ticket_number, amount, source FROM top_k_sales
        UNION ALL
        SELECT customer_sk, ticket_number, amount, source FROM top_k_returns
    ),
    exclude_keys AS (
        SELECT cr_refunded_customer_sk AS customer_sk
        FROM catalog_returns
        WHERE cr_return_amount > 500
    ),
    final_set AS (
        SELECT customer_sk, ticket_number, amount, source
        FROM combined
        EXCEPT
        SELECT
            customer_sk,
            CAST(NULL AS integer) AS ticket_number,
            CAST(NULL AS decimal(7,2)) AS amount,
            CAST(NULL AS varchar) AS source
        FROM exclude_keys
    )
SELECT customer_sk, ticket_number, amount, source
FROM final_set
ORDER BY source, amount DESC
