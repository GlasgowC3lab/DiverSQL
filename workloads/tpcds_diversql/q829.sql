WITH
  sr_agg AS (
    SELECT
      sr_returned_date_sk,
      sr_hdemo_sk,
      COUNT(*) AS return_cnt,
      SUM(sr_return_amt) AS total_return_amt,
      AVG(sr_return_tax) AS avg_return_tax,
      MIN(sr_fee) AS min_fee,
      MAX(sr_fee) AS max_fee
    FROM store_returns
    WHERE sr_fee > 10.00
      AND sr_return_tax >= 0.5
    GROUP BY sr_returned_date_sk, sr_hdemo_sk
  ),
  cp_dates AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_catalog_page_id,
      d.d_date_sk,
      cp.cp_department,
      cp.cp_type
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_type = 'A'
  ),
  promo_dates AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_id,
      d.d_date_sk,
      p.p_channel_tv,
      p.p_discount_active
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_channel_tv = 'N'
  ),
  combined AS (
    SELECT
      sr.sr_returned_date_sk,
      d.d_year,
      sr.return_cnt,
      sr.total_return_amt,
      sr.avg_return_tax,
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      cp.cp_catalog_page_id,
      promo.p_promo_id,
      hd_income.cnt AS same_income_household_cnt,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY sr.total_return_amt DESC) AS return_rank
    FROM sr_agg sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN cp_dates cp ON d.d_date_sk = cp.d_date_sk
    FULL OUTER JOIN promo_dates promo ON d.d_date_sk = promo.d_date_sk
    LEFT JOIN LATERAL (
      SELECT COUNT(*) AS cnt
      FROM household_demographics hd2
      WHERE hd2.hd_income_band_sk = hd.hd_income_band_sk
    ) AS hd_income ON TRUE
    WHERE d.d_month_seq BETWEEN 1200 AND 1300
      AND hd.hd_vehicle_count >= 2
      AND (cp.cp_catalog_page_id IS NOT NULL OR promo.p_promo_id IS NOT NULL)
  )
SELECT
  d_year,
  return_cnt,
  total_return_amt,
  avg_return_tax,
  hd_income_band_sk,
  hd_vehicle_count,
  cp_catalog_page_id,
  p_promo_id,
  same_income_household_cnt,
  return_rank
FROM combined
ORDER BY d_year DESC, return_rank
LIMIT 100
