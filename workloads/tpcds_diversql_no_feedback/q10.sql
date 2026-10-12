WITH returns_data AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_year,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        ca.ca_street_type,
        ca.ca_city,
        regexp_extract(r.r_reason_desc, '^(\\w+)', 1) AS reason_first_word,
        ca.ca_city || ', ' || ca.ca_street_type AS concatenated_location
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND ca.ca_gmt_offset = -5.00
      AND regexp_like(r.r_reason_desc, '(?i)price|warranty')
)
SELECT
    d_year,
    reason_first_word,
    COUNT(*) AS cnt_returns,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_amt) AS avg_return_amt,
    SUM(sr_net_loss) AS total_net_loss,
    MAX(concatenated_location) AS sample_location
FROM returns_data
WHERE reason_first_word LIKE 'F%'
GROUP BY d_year, reason_first_word
HAVING COUNT(*) > 10
ORDER BY total_return_amt DESC
LIMIT 100
