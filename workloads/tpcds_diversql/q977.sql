WITH base AS (
  SELECT
    c.c_customer_sk,
    i.ib_lower_bound,
    i.ib_upper_bound,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    (c.c_birth_year + c.c_birth_month / 12.0) AS approx_age_factor
  FROM customer c
  FULL OUTER JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  INNER JOIN income_band i
    ON hd.hd_income_band_sk = i.ib_income_band_sk
  WHERE hd.hd_dep_count > 2
    AND i.ib_upper_bound <= 100000
    AND c.c_birth_month IN (3, 5, 6)
    AND EXISTS (
      SELECT 1 FROM customer c2
      WHERE c2.c_current_cdemo_sk = c.c_current_cdemo_sk
        AND c2.c_birth_year > 1980
    )
    AND hd.hd_demo_sk IN (
      SELECT DISTINCT c3.c_current_hdemo_sk
      FROM customer c3
      WHERE c3.c_preferred_cust_flag = 'Y'
    )
),
agg1 AS (
  SELECT
    c_customer_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    SUM(hd_dep_count) AS total_dep,
    AVG(approx_age_factor) AS avg_age_factor
  FROM base
  GROUP BY c_customer_sk, ib_lower_bound, ib_upper_bound, hd_buy_potential
),
union_set AS (
  SELECT
    c_customer_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    total_dep,
    avg_age_factor
  FROM agg1
  WHERE avg_age_factor > 30
  UNION
  SELECT
    c_customer_sk,
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    total_dep,
    avg_age_factor
  FROM agg1
  WHERE hd_buy_potential LIKE '5%'
)
SELECT
  hd_buy_potential,
  COUNT(DISTINCT c_customer_sk) AS customer_cnt,
  AVG(avg_age_factor) AS overall_avg_age,
  SUM(total_dep) AS overall_dep
FROM union_set
GROUP BY hd_buy_potential
HAVING COUNT(DISTINCT c_customer_sk) > 5
ORDER BY overall_avg_age DESC
LIMIT 100
