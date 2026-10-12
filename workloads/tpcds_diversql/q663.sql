WITH
  sr_agg AS (
    SELECT
      sr.sr_cdemo_sk,
      sr.sr_hdemo_sk,
      SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
      COUNT(*) AS return_cnt
    FROM tpcds.store_returns sr
    TABLESAMPLE BERNOULLI (10)
    WHERE sr.sr_return_tax > 20
      AND sr.sr_return_quantity > 1
      AND sr.sr_return_time_sk BETWEEN 40000 AND 50000
    GROUP BY sr.sr_cdemo_sk, sr.sr_hdemo_sk
  ),
  catalog_full AS (
    SELECT
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_refunded_cdemo_sk,
      cr.cr_refunded_hdemo_sk,
      cr.cr_ship_mode_sk,
      cp.cp_department,
      cp.cp_catalog_page_number,
      cp.cp_catalog_number
    FROM tpcds.catalog_returns cr
    FULL OUTER JOIN tpcds.catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  ),
  web_full AS (
    SELECT
      wr.wr_return_amt,
      wr.wr_return_quantity,
      wr.wr_refunded_cdemo_sk,
      wr.wr_refunded_hdemo_sk,
      wp.wp_type,
      wp.wp_char_count
    FROM tpcds.web_returns wr
    JOIN tpcds.web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
  ),
  joined AS (
    SELECT
      sr.sr_cdemo_sk,
      cd.cd_gender,
      hd.hd_buy_potential,
      sm.sm_carrier,
      sm.sm_contract,
      cf.cp_department,
      cf.cp_catalog_page_number,
      sr.total_return_inc_tax,
      COALESCE(cf.cr_return_amount, 0) AS cat_ret_amt,
      COALESCE(wf.wr_return_amt, 0) AS web_ret_amt
    FROM sr_agg sr
    JOIN tpcds.customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_full cf
      ON cf.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.ship_mode sm
      ON cf.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_full wf
      ON wf.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE sm.sm_contract LIKE 'A%'
      AND cf.cp_catalog_number > 50
      AND ib.ib_lower_bound >= 20000
      AND wf.wp_type = 'content'
      AND hd.hd_vehicle_count > 1
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns cr2
            WHERE cr2.cr_refunded_cdemo_sk = sr.sr_cdemo_sk
          )
      AND cf.cp_department IS NOT NULL
  ),
  ranked AS (
    SELECT
      j.*,
      ROW_NUMBER() OVER (PARTITION BY j.sm_carrier ORDER BY j.total_return_inc_tax DESC) AS rnk,
      SUM(j.cat_ret_amt) OVER (PARTITION BY j.sm_carrier) AS total_catalog_return_amount,
      SUM(j.web_ret_amt) OVER (PARTITION BY j.sm_carrier) AS total_web_return_amount,
      COUNT(DISTINCT j.cd_gender) OVER (PARTITION BY j.sm_carrier) AS distinct_gender_cnt,
      COUNT(DISTINCT j.hd_buy_potential) OVER (PARTITION BY j.sm_carrier) AS distinct_buy_potential_cnt
    FROM joined j
  )
SELECT
  sr_cdemo_sk,
  cd_gender,
  hd_buy_potential,
  sm_carrier,
  sm_contract,
  cp_department,
  cp_catalog_page_number,
  total_return_inc_tax,
  total_catalog_return_amount,
  total_web_return_amount,
  distinct_gender_cnt,
  distinct_buy_potential_cnt,
  rnk
FROM ranked
WHERE rnk <= 5
ORDER BY sm_carrier, rnk
LIMIT 100
