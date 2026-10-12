WITH filtered_sr AS (
    SELECT sr.*, d.d_year, d.d_month_seq
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sr.sr_fee > 20
      AND sr.sr_return_amt > 100
      AND sr.sr_return_quantity >= 1
      AND sr.sr_net_loss > 0
),
filtered_wr AS (
    SELECT wr.*, d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND wr.wr_return_amt > 150
)
SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    ws.web_name,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    AVG(COALESCE(sr.sr_fee, 0) + COALESCE(wr.wr_fee, 0)) AS avg_total_fee
FROM date_dim d
LEFT JOIN filtered_sr sr ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN filtered_wr wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, wr.wr_reason_sk)
LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
LEFT JOIN web_site ws ON ws.web_close_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1 AND 12
  AND cc.cc_state = 'CA'
  AND ws.web_state = 'CA'
  AND EXISTS (
      SELECT 1
      FROM reason r2
      WHERE r2.r_reason_desc LIKE '%color%'
        AND r2.r_reason_sk = r.r_reason_sk
  )
GROUP BY d.d_year, d.d_month_seq, cc.cc_name, ws.web_name, r.r_reason_desc
ORDER BY total_store_return_amt DESC
LIMIT 100
