WITH sr_sample AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    i.i_item_id,
    c.c_customer_id,
    sr.sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sr.sr_return_amt DESC) AS rn_year,
    RANK() OVER (ORDER BY sr.sr_return_amt DESC) AS rnk_global,
    CASE
        WHEN sr.sr_return_amt > 100 THEN 'High'
        WHEN sr.sr_return_amt > 50 THEN 'Medium'
        ELSE 'Low'
    END AS amount_category
FROM sr_sample sr
FULL OUTER JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
WHERE
    sr.sr_return_amt > 0
    AND d.d_fy_week_seq IN (3, 15, 20)
    AND i.i_manufact LIKE '%station%'
    AND sr.sr_customer_sk IN (
        SELECT c2.c_customer_sk
        FROM customer c2
        WHERE c2.c_birth_month = 2
    )
ORDER BY d.d_year DESC, rn_year
LIMIT 100
