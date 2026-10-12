WITH
  catalog_filtered AS (
    SELECT
      cs.cs_bill_hdemo_sk AS household_demo_sk,
      SUM(cs.cs_net_profit) AS total_catalog_profit,
      MIN(cs.cs_sold_date_sk) AS first_sold_date_sk
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_company = 5
      AND sm.sm_code = 'AIR'
      AND cs.cs_bill_hdemo_sk IN (
        SELECT hd.hd_demo_sk
        FROM tpcds.household_demographics hd
        WHERE hd.hd_income_band_sk = 8
      )
    GROUP BY cs.cs_bill_hdemo_sk
  ),
  store_filtered AS (
    SELECT
      ss.ss_hdemo_sk AS household_demo_sk,
      SUM(ss.ss_net_profit) AS total_store_profit,
      MAX(ss.ss_sold_date_sk) AS latest_sold_date_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count >= 3
    GROUP BY ss.ss_hdemo_sk
  ),
  full_joined AS (
    SELECT
      cf.household_demo_sk,
      cf.total_catalog_profit,
      sf.total_store_profit,
      cf.first_sold_date_sk,
      sf.latest_sold_date_sk
    FROM catalog_filtered cf
    FULL OUTER JOIN store_filtered sf
      ON cf.household_demo_sk = sf.household_demo_sk
  ),
  lateral_max_ship_date AS (
    SELECT
      fj.*, 
      ls.max_ship_date_sk
    FROM full_joined fj
    LEFT JOIN LATERAL (
      SELECT MAX(cs.cs_ship_date_sk) AS max_ship_date_sk
      FROM tpcds.catalog_sales cs
      WHERE cs.cs_bill_hdemo_sk = fj.household_demo_sk
    ) ls ON TRUE
  ),
  intersect_households AS (
    SELECT household_demo_sk FROM catalog_filtered
    INTERSECT
    SELECT household_demo_sk FROM store_filtered
  ),
  except_households AS (
    SELECT household_demo_sk FROM catalog_filtered
    EXCEPT
    SELECT household_demo_sk FROM store_filtered
  ),
  union_part AS (
    SELECT
      lj.household_demo_sk,
      lj.total_catalog_profit,
      lj.total_store_profit,
      lj.first_sold_date_sk,
      lj.latest_sold_date_sk,
      lj.max_ship_date_sk,
      'both' AS source
    FROM lateral_max_ship_date lj
    WHERE lj.household_demo_sk IN (SELECT household_demo_sk FROM intersect_households)

    UNION ALL

    SELECT
      eh.household_demo_sk,
      cf.total_catalog_profit,
      NULL AS total_store_profit,
      cf.first_sold_date_sk,
      NULL AS latest_sold_date_sk,
      NULL AS max_ship_date_sk,
      'catalog_only' AS source
    FROM except_households eh
    LEFT JOIN catalog_filtered cf ON eh.household_demo_sk = cf.household_demo_sk
  )
SELECT
  household_demo_sk,
  total_catalog_profit,
  total_store_profit,
  first_sold_date_sk,
  latest_sold_date_sk,
  max_ship_date_sk,
  source
FROM union_part
ORDER BY household_demo_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
