WITH avg_tax AS (
  SELECT AVG(s_tax_percentage) AS avg_tax
  FROM store
)
SELECT store_name, return_year, total_return_amount
FROM (
  SELECT
    s.s_store_name AS store_name,
    d.d_year AS return_year,
    SUM(sr.sr_return_amt) AS total_return_amount
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND s.s_tax_percentage > (SELECT avg_tax FROM avg_tax)
  GROUP BY s.s_store_name, d.d_year

  UNION ALL

  SELECT
    s.s_store_name AS store_name,
    d.d_year AS return_year,
    SUM(sr.sr_return_amt) AS total_return_amount
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc LIKE '%model%'
    AND d.d_year = 2002
    AND s.s_tax_percentage > (SELECT avg_tax FROM avg_tax)
  GROUP BY s.s_store_name, d.d_year
) combined
ORDER BY total_return_amount DESC
LIMIT 100
