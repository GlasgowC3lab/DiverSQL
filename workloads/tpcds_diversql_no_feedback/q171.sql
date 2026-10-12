WITH combined AS (
    SELECT
        ca.ca_county,
        ca.ca_location_type,
        r.r_reason_desc,
        sr.sr_return_amt_inc_tax AS return_amount,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt_inc_tax > 200
    UNION ALL
    SELECT
        ca.ca_county,
        ca.ca_location_type,
        r.r_reason_desc,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt_inc_tax <= 200
)
SELECT
    ca_county,
    ca_location_type,
    r_reason_desc,
    SUM(return_amount) AS total_return_amount,
    SUM(return_quantity) AS total_return_quantity
FROM combined
GROUP BY ROLLUP (ca_county, ca_location_type, r_reason_desc)
ORDER BY ca_county, ca_location_type, r_reason_desc
LIMIT 100
