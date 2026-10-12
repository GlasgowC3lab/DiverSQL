WITH store_only AS (
    SELECT
        c.c_customer_id,
        s.s_store_name,
        SUM(sr.sr_return_amt) AS total_return,
        'store' AS source
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
          AND cr.cr_returned_date_sk = sr.sr_returned_date_sk
    )
    GROUP BY c.c_customer_id, s.s_store_name
),
catalog_only AS (
    SELECT
        c.c_customer_id,
        CAST(NULL AS varchar) AS s_store_name,
        SUM(cr.cr_return_amount) AS total_return,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_returned_date_sk = cr.cr_returned_date_sk
    )
    GROUP BY c.c_customer_id
)
SELECT
    c_customer_id,
    s_store_name,
    total_return,
    source
FROM store_only
UNION ALL
SELECT
    c_customer_id,
    s_store_name,
    total_return,
    source
FROM catalog_only
ORDER BY total_return DESC, source
