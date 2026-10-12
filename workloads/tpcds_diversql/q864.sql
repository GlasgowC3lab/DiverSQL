WITH recent_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    r.r_reason_desc AS reason,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_count
FROM web_returns AS wr
TABLESAMPLE BERNOULLI (10)
JOIN recent_dates rd ON wr.wr_returned_date_sk = rd.d_date_sk
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = i.i_item_sk
      AND p.p_start_date_sk = d.d_date_sk
)
GROUP BY r.r_reason_desc

UNION

SELECT
    r.r_reason_desc AS reason,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_count
FROM store_returns AS sr
TABLESAMPLE BERNOULLI (10)
JOIN recent_dates rd ON sr.sr_returned_date_sk = rd.d_date_sk
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE d.d_month_seq = 120
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
