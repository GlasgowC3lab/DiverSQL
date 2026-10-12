/*
  Goal: Identify store‑year combinations (including roll‑ups by store only and by year only) that have sales records but no matching return records. The query uses GROUPING SETS to produce detailed and aggregated rows, then subtracts the return set from the sales set with EXCEPT, orders the result, and limits it to 100 rows.
*/
WITH
  sales_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_year AS year,
      SUM(ss.ss_ext_sales_price) AS total_amount
    FROM tpcds.store_sales ss
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
      (s.s_store_id, d.d_year),
      (s.s_store_id),
      (d.d_year)
    )
  ),
  returns_agg AS (
    SELECT
      s.s_store_id AS store_id,
      d.d_year AS year,
      SUM(sr.sr_return_amt) AS total_amount
    FROM tpcds.store_returns sr
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
      (s.s_store_id, d.d_year),
      (s.s_store_id),
      (d.d_year)
    )
  )
SELECT
  store_id,
  year,
  total_amount
FROM sales_agg
EXCEPT
SELECT
  store_id,
  year,
  total_amount
FROM returns_agg
ORDER BY store_id ASC NULLS LAST, year ASC
LIMIT 100
