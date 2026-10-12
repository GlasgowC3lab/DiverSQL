SELECT
    d.d_date,
    s.s_store_name,
    r.r_reason_desc,
    d_closed.d_date AS store_closed_date,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txns,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(sr.sr_return_tax) AS store_return_tax,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_txns,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(wr.wr_return_tax) AS web_return_tax,
    COALESCE(SUM(sr.sr_return_amt), 0) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_return_diff
FROM date_dim d
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2023
GROUP BY d.d_date, s.s_store_name, r.r_reason_desc, d_closed.d_date
HAVING SUM(sr.sr_return_amt) > 0
ORDER BY d.d_date DESC, store_return_amount DESC
LIMIT 100
