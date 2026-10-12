/*
  Goal: Analyze return amounts across catalog, store, and web channels, broken down by year, month, customer gender, household income band, catalog page type, promotion name, and ship mode. The query applies realistic filters, samples catalog returns, uses a full outer join to retain unmatched store/web returns, includes a correlated EXISTS clause, and demonstrates a CASE expression for return size classification.
*/
WITH
  -- Sampled catalog returns with a basic filter
  sampled_catalog_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_quantity > 1
  ),

  -- Filtered catalog page (electronics department)
  filtered_catalog_page AS (
    SELECT *
    FROM catalog_page
    WHERE cp_department = 'Electronics'
  ),

  -- Filtered promotion records
  filtered_promotion AS (
    SELECT *
    FROM promotion
    WHERE p_response_target = 1
      AND p_purpose = 'Unknown'
  ),

  -- Filtered ship mode records
  filtered_ship_mode AS (
    SELECT *
    FROM ship_mode
    WHERE sm_ship_mode_id LIKE 'AAAAAAAAB%'
      AND sm_contract = '2mM8l'
  ),

  -- Store returns with a quantity filter
  filtered_store_returns AS (
    SELECT *
    FROM store_returns
    WHERE sr_return_quantity >= 2
  ),

  -- Web returns with a quantity filter
  filtered_web_returns AS (
    SELECT *
    FROM web_returns
    WHERE wr_return_quantity >= 2
  )

SELECT
  d.d_year,
  d.d_month_seq,
  cd.cd_gender,
  hd.hd_income_band_sk,
  cp.cp_type,
  p.p_promo_name,
  sm.sm_type,
  CASE WHEN cr.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END AS return_category,
  SUM(cr.cr_return_amount)          AS total_catalog_return_amount,
  SUM(sr.sr_return_amt)             AS total_store_return_amount,
  SUM(wr.wr_return_amt)             AS total_web_return_amount,
  COUNT(*)                           AS transaction_cnt,
  SUM(CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END) AS high_return_cnt
FROM date_dim d

  -- Mandatory inner joins to bring in the core catalog return data
  JOIN sampled_catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN filtered_catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN filtered_ship_mode sm      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN filtered_promotion p       ON p.p_start_date_sk <= d.d_date_sk
                                    AND p.p_end_date_sk   >= d.d_date_sk
  JOIN customer_demographics cd   ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk

  -- Full outer joins to retain unmatched store and web returns
  FULL OUTER JOIN filtered_store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
  FULL OUTER JOIN filtered_web_returns   wr ON wr.wr_returned_date_sk = d.d_date_sk

WHERE
  -- Additional selective predicates
  cd.cd_purchase_estimate BETWEEN 1500 AND 8000
  AND cd.cd_dep_count BETWEEN 1 AND 5
  AND hd.hd_buy_potential = 'HIGH'
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_number = cp.cp_catalog_number
          AND cp2.cp_department = 'Electronics'
      )

GROUP BY
  d.d_year,
  d.d_month_seq,
  cd.cd_gender,
  hd.hd_income_band_sk,
  cp.cp_type,
  p.p_promo_name,
  sm.sm_type,
  CASE WHEN cr.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END

ORDER BY total_catalog_return_amount DESC
LIMIT 100
