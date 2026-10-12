WITH sales AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_date AS event_date,
        'sale' AS event_type,
        ss.ss_net_paid AS amount,
        CASE WHEN ss.ss_net_paid >= 0 THEN 'Positive' ELSE 'Negative' END AS amount_sign
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 0
),
returns AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_date AS event_date,
        'return' AS event_type,
        sr.sr_return_amt AS amount,
        CASE WHEN sr.sr_return_amt >= 0 THEN 'Positive' ELSE 'Negative' END AS amount_sign
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND sr.sr_return_quantity > 0
)
SELECT
    store_id,
    event_date,
    event_type,
    amount,
    amount_sign,
    ROW_NUMBER() OVER (ORDER BY amount DESC) AS rn
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) combined
ORDER BY amount DESC
LIMIT 100
