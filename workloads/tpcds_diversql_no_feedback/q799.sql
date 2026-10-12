WITH small_dates AS (
   SELECT d_date_sk,
          d_year,
          d_month_seq,
          d_date_id,
          d_dow
   FROM date_dim
   WHERE REGEXP_LIKE(d_date_id, '^AAAAAAA[AL]')
     AND d_date_id LIKE 'AAAAAAA%'
     AND d_dow BETWEEN 1 AND 5
   LIMIT 500
),
year_set AS (
   SELECT DISTINCT d_year
   FROM date_dim
   WHERE d_year BETWEEN 1998 AND 2000
)
SELECT
   src.source,
   d.d_year,
   d.d_month_seq,
   SUM(src.ret_amount) AS total_ret_amount,
   SUM(src.net_loss)   AS total_net_loss,
   CONCAT(src.source, '_', CAST(d.d_year AS VARCHAR)) AS source_year_key,
   MIN(SUBSTRING(src.d_date_id, 1, 8)) AS date_prefix
FROM (
   SELECT 'Store'   AS source,
          sd.d_year,
          sd.d_month_seq,
          sr.sr_return_amt   AS ret_amount,
          sr.sr_net_loss     AS net_loss,
          sd.d_date_id
   FROM small_dates sd
   JOIN store_returns sr
     ON sr.sr_returned_date_sk = sd.d_date_sk
   UNION ALL
   SELECT 'Catalog' AS source,
          sd.d_year,
          sd.d_month_seq,
          cr.cr_return_amount AS ret_amount,
          cr.cr_net_loss      AS net_loss,
          sd.d_date_id
   FROM small_dates sd
   JOIN catalog_returns cr
     ON cr.cr_returned_date_sk = sd.d_date_sk
) src
JOIN small_dates d
  ON src.d_year = d.d_year
 AND src.d_month_seq = d.d_month_seq
CROSS JOIN year_set y
WHERE d.d_year = y.d_year
GROUP BY CUBE(src.source, d.d_year, d.d_month_seq)
ORDER BY total_ret_amount DESC
LIMIT 100
