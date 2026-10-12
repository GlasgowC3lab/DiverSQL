WITH returning_addresses AS (
    SELECT DISTINCT wr_returning_addr_sk AS address_sk
    FROM web_returns
    WHERE regexp_like(CAST(wr_return_quantity AS varchar), '^1[0-9]$')
),
refunded_addresses AS (
    SELECT DISTINCT wr_refunded_addr_sk AS address_sk
    FROM web_returns
    WHERE wr_return_amt > (SELECT AVG(wr_return_amt) FROM web_returns)
),
common_addresses AS (
    SELECT address_sk FROM returning_addresses
    INTERSECT
    SELECT address_sk FROM refunded_addresses
),
address_details AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ca_suite_number,
        ca_street_type,
        CONCAT(ca_city, ', ', ca_state) AS city_state,
        CASE WHEN regexp_like(ca_suite_number, '^Suite [A-Z]$') THEN 1 ELSE 0 END AS suite_letter_flag
    FROM customer_address
    WHERE ca_country = 'United States'
      AND (ca_street_type LIKE '%Drive%' OR ca_street_type LIKE '%Cir.%')
)
SELECT
    ad.ca_state,
    ad.ca_country,
    ad.suite_letter_flag,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    MAX(wr.wr_return_amt) AS max_return_amt
FROM web_returns wr
JOIN common_addresses ca ON wr.wr_returning_addr_sk = ca.address_sk
JOIN address_details ad ON ad.ca_address_sk = ca.address_sk
WHERE wr.wr_return_amt > (
        SELECT MIN(wr_return_amt)
        FROM web_returns
        WHERE wr_return_quantity > 5
    )
GROUP BY CUBE (ad.ca_state, ad.ca_country, ad.suite_letter_flag)
HAVING SUM(wr.wr_return_amt) > (SELECT AVG(wr_return_amt) FROM web_returns)
ORDER BY total_return_amount DESC
LIMIT 100
