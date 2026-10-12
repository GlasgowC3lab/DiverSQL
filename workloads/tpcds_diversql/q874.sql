WITH hd_agg AS (
  SELECT
    hd_income_band_sk,
    COUNT(*) AS household_cnt,
    AVG(hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(CASE WHEN hd_buy_potential = '0-500' THEN 1 ELSE 0 END) AS cnt_buy_0_500,
    SUM(CASE WHEN hd_buy_potential = '>10000' THEN 1 ELSE 0 END) AS cnt_buy_gt_10000
  FROM household_demographics
  WHERE hd_vehicle_count >= 0
    AND hd_dep_count BETWEEN 0 AND 10
    AND hd_buy_potential NOT IN ('Unknown')
    AND hd_demo_sk IN (
      SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count >= 2
    )
  GROUP BY hd_income_band_sk
),
joined AS (
  SELECT
    COALESCE(agg.hd_income_band_sk, ib.ib_income_band_sk) AS income_band_sk,
    agg.household_cnt,
    agg.avg_vehicle_cnt,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
      WHEN ib.ib_upper_bound > 150000 THEN 'High Income'
      ELSE 'Mid/Low Income'
    END AS income_category
  FROM hd_agg agg
  FULL OUTER JOIN income_band ib
    ON agg.hd_income_band_sk = ib.ib_income_band_sk
  WHERE (ib.ib_lower_bound IS NOT NULL AND ib.ib_lower_bound >= 0)
    AND (ib.ib_upper_bound IS NOT NULL AND ib.ib_upper_bound <= 200000)
    AND (agg.avg_vehicle_cnt IS NOT NULL AND agg.avg_vehicle_cnt > 0)
    AND (agg.household_cnt >= 1)
    AND (ib.ib_income_band_sk IS NOT NULL OR agg.hd_income_band_sk IS NOT NULL)
)
SELECT
  income_band_sk,
  household_cnt,
  avg_vehicle_cnt,
  ib_lower_bound,
  ib_upper_bound,
  income_category,
  RANK() OVER (PARTITION BY income_category ORDER BY avg_vehicle_cnt DESC) AS rank_within_category
FROM joined
WHERE EXISTS (
  SELECT 1 FROM income_band ib2
  WHERE ib2.ib_income_band_sk = joined.income_band_sk
    AND ib2.ib_upper_bound BETWEEN 50000 AND 200000
)
UNION
SELECT
  income_band_sk,
  household_cnt,
  avg_vehicle_cnt,
  ib_lower_bound,
  ib_upper_bound,
  income_category,
  RANK() OVER (PARTITION BY income_category ORDER BY avg_vehicle_cnt DESC) AS rank_within_category
FROM joined
WHERE NOT EXISTS (
  SELECT 1 FROM income_band ib2
  WHERE ib2.ib_income_band_sk = joined.income_band_sk
    AND ib2.ib_upper_bound BETWEEN 50000 AND 200000
)
ORDER BY rank_within_category, avg_vehicle_cnt DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
