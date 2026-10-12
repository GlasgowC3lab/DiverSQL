WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk AS store_sk,
      d.d_date_sk,
      SUM(ss.ss_net_paid) AS amount,
      'sales' AS source_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2000
    GROUP BY ss.ss_store_sk, d.d_date_sk
  ),
  returns_agg AS (
    SELECT
      sr.sr_store_sk AS store_sk,
      d.d_date_sk,
      SUM(sr.sr_net_loss) AS amount,
      'returns' AS source_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
    GROUP BY sr.sr_store_sk, d.d_date_sk
  ),
  union_all_data AS (
    SELECT store_sk, d_date_sk, amount, source_type FROM sales_agg
    UNION ALL
    SELECT store_sk, d_date_sk, amount, source_type FROM returns_agg
  ),
  catalog_dates AS (
    SELECT d.d_date_sk, cp.cp_description, cp.cp_catalog_page_sk
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_date_sk, cp.cp_description, cp.cp_catalog_page_sk
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
  )
SELECT
  ud.store_sk,
  ud.d_date_sk,
  ud.amount,
  ud.source_type,
  cd.cp_description
FROM union_all_data ud
FULL OUTER JOIN catalog_dates cd ON ud.d_date_sk = cd.d_date_sk
ORDER BY ud.amount DESC
LIMIT 100
