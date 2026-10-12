WITH filtered_returns AS (
    SELECT
        sr_customer_sk,
        sr_return_amt,
        sr_return_tax,
        sr_return_quantity
    FROM store_returns
    WHERE sr_return_tax > 5.00
      AND sr_return_quantity BETWEEN 10 AND 60
),
customer_filtered AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_last_review_date
    FROM customer
    WHERE c_birth_month IN (1, 5, 9)
      AND c_last_review_date > 2452400
),
intersect_keys AS (
    SELECT sr_customer_sk FROM store_returns WHERE sr_return_tax > 10.00
    INTERSECT
    SELECT c_customer_sk FROM customer WHERE c_birth_month = 7
),
joined AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_quantity
    FROM customer_filtered c
    JOIN filtered_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > sr.sr_return_amt
    )
    AND c.c_customer_sk IN (SELECT * FROM intersect_keys)
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_tax) AS avg_return_tax,
    MIN(sr_return_quantity) AS min_quantity,
    MAX(sr_return_quantity) AS max_quantity
FROM joined
GROUP BY c_customer_sk, c_first_name, c_last_name
ORDER BY total_return_amount DESC
LIMIT 100
