WITH
  store_agg AS (
    SELECT d.d_date,
           SUM(sr.sr_return_amt) AS store_return_amt,
           SUM(sr.sr_fee) AS store_fee_total,
           COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
  ),
  web_agg AS (
    SELECT d.d_date,
           SUM(wr.wr_return_amt) AS web_return_amt,
           SUM(wr.wr_fee) AS web_fee_total,
           COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
  ),
  full_join AS (
    SELECT COALESCE(s.d_date, w.d_date) AS return_date,
           s.store_return_amt,
           w.web_return_amt,
           s.store_fee_total,
           w.web_fee_total,
           s.store_return_cnt,
           w.web_return_cnt
    FROM store_agg s
    FULL OUTER JOIN web_agg w
      ON s.d_date = w.d_date
  )
SELECT
  fj.return_date AS return_date,
  (COALESCE(fj.store_return_amt, 0) + COALESCE(fj.web_return_amt, 0)) AS total_return_amount,
  (COALESCE(fj.store_return_cnt, 0) + COALESCE(fj.web_return_cnt, 0)) AS total_return_cnt
FROM full_join fj
WHERE (COALESCE(fj.store_return_amt, 0) + COALESCE(fj.web_return_amt, 0)) > 1000
UNION ALL
SELECT
  d.d_date,
  SUM(sr.sr_return_amt) AS total_return_amount,
  COUNT(*) AS total_return_cnt
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE d.d_month_seq BETWEEN 1200 AND 1202
GROUP BY d.d_date
ORDER BY total_return_amount DESC
LIMIT 100
