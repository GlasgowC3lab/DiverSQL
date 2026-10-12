/*
Goal: Compare yearly total return amounts from store returns (male customers) with yearly net sales amounts from web sales (female customers) for the years 2001‑2003, deduplicate via UNION, and show the first 100 rows.
*/
WITH date_year AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2001 AND 2003
)
SELECT year,
       source,
       total_amount
FROM (
    -- Store returns aggregated by year for male customers
    SELECT
        dy.d_year AS year,
        'store_return' AS source,
        SUM(sr.sr_return_amt) AS total_amount
    FROM store_returns sr
    JOIN date_year dy ON sr.sr_returned_date_sk = dy.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_salutation = 'Mr.'
    GROUP BY dy.d_year
    UNION
    -- Web sales aggregated by year for female customers, using a LATERAL subquery to compute net price
    SELECT
        dy.d_year AS year,
        'web_sales' AS source,
        SUM(l.net_price) AS total_amount
    FROM web_sales ws
    JOIN date_year dy ON ws.ws_sold_date_sk = dy.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT ws.ws_ext_sales_price - ws.ws_ext_discount_amt AS net_price
    ) AS l
    WHERE c.c_salutation = 'Mrs.'
    GROUP BY dy.d_year
) AS combined
ORDER BY year, source
LIMIT 100
