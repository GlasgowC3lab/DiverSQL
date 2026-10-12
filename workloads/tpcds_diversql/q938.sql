/*
Goal: Analyse the relationship between call‑center activity and store returns by date, applying string pattern filters, a full outer join, aggregation with GROUPING SETS, a ranking window, a UNION DISTINCT, and a scalar subquery for the maximum daily net paid amount.
*/
WITH
  /* Call‑center rows with string filters */
  cc AS (
    SELECT
      d.d_date,
      d.d_year,
      cc.cc_company_name,
      CONCAT(cc.cc_name, ' - ', cc.cc_city) AS cc_full_name,
      CASE WHEN regexp_like(cc.cc_company_name, '^a') THEN 1 ELSE 0 END AS starts_with_a
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d
      ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_country = 'United States'
      AND cc.cc_company_name IS NOT NULL
  ),
  /* Store‑return rows with text predicates */
  sr AS (
    SELECT
      d.d_date,
      d.d_year,
      sr.sr_return_amt_inc_tax,
      sr.sr_store_credit,
      sr.sr_fee,
      sr.sr_ticket_number
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_amt_inc_tax > 100
      AND d.d_holiday LIKE '%Day%'
  ),
  /* Full outer join of the two streams – keeps unmatched rows */
  full_join AS (
    SELECT
      COALESCE(cc.d_date, sr.d_date)               AS event_date,
      COALESCE(cc.d_year, sr.d_year)               AS year,
      cc.cc_company_name,
      cc.cc_full_name,
      cc.starts_with_a,
      sr.sr_return_amt_inc_tax,
      sr.sr_store_credit,
      sr.sr_fee,
      sr.sr_ticket_number
    FROM cc
    FULL OUTER JOIN sr
      ON cc.d_date = sr.d_date
  ),
  /* Summary of catalog sales per year (used later) */
  cs_summary AS (
    SELECT
      d.d_year,
      SUM(cs.cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
      COUNT(*)                     AS cnt_sales
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_net_paid_inc_ship > 500
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
  ),
  /* Two SELECTs combined with UNION DISTINCT */
  union_data AS (
    SELECT
      fj.year,
      fj.cc_company_name                     AS company,
      fj.sr_return_amt_inc_tax               AS return_amt,
      cs.total_net_paid_inc_ship             AS net_paid
    FROM full_join fj
    LEFT JOIN cs_summary cs
      ON fj.year = cs.d_year
    WHERE fj.starts_with_a = 1
    UNION DISTINCT
    SELECT
      fj.year,
      NULL                                   AS company,
      fj.sr_return_amt_inc_tax               AS return_amt,
      cs.total_net_paid_inc_ship             AS net_paid
    FROM full_join fj
    LEFT JOIN cs_summary cs
      ON fj.year = cs.d_year
    WHERE fj.sr_fee > 60
  )
SELECT
  year,
  company,
  SUM(return_amt)                         AS total_return_inc_tax,
  SUM(net_paid)                           AS total_net_paid_inc_ship,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY SUM(return_amt) DESC) AS rank_by_return,
  (
    SELECT MAX(cs2.cs_net_paid_inc_ship)
    FROM tpcds.catalog_sales cs2
    JOIN tpcds.date_dim d2
      ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = union_data.year
  )                                        AS max_daily_net_paid,
  MAX(return_amt)                         AS max_return_amt,
  MIN(net_paid)                           AS min_net_paid
FROM union_data
GROUP BY GROUPING SETS (
  (year, company),
  (year),
  ()
)
ORDER BY year DESC, total_return_inc_tax DESC
LIMIT 100
