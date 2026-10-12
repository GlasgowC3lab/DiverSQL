WITH set_a AS (
   SELECT c.c_current_hdemo_sk AS hdemo_sk,
          hd.hd_income_band_sk
   FROM customer c
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE c.c_preferred_cust_flag = 'Y'
     AND c.c_birth_year BETWEEN 1960 AND 1980
     AND hd.hd_dep_count BETWEEN 2 AND 8
     AND hd.hd_vehicle_count >= 1
     AND c.c_first_sales_date_sk BETWEEN 2450000 AND 2453000
     AND c.c_last_review_date >= 2452300
),
set_b AS (
   SELECT c.c_current_hdemo_sk AS hdemo_sk,
          hd.hd_income_band_sk
   FROM customer c
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE c.c_salutation = 'Mr.'
     AND c.c_birth_month = 7
     AND hd.hd_vehicle_count = 2
     AND hd.hd_dep_count = 5
     AND c.c_birth_country = 'United States'
     AND c.c_last_review_date <= 2452500
),
common_groups AS (
   SELECT hdemo_sk, hd_income_band_sk
   FROM set_a
   INTERSECT
   SELECT hdemo_sk, hd_income_band_sk
   FROM set_b
),
agg AS (
   SELECT
       c.c_current_hdemo_sk,
       hd.hd_income_band_sk,
       COUNT(*) AS cust_count,
       AVG(c.c_birth_year) AS avg_birth_year,
       SUM(hd.hd_dep_count) AS total_dep,
       MIN(c.c_last_review_date) AS min_last_review,
       MAX(c.c_last_review_date) AS max_last_review
   FROM customer c
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE (c.c_current_hdemo_sk, hd.hd_income_band_sk) IN (
         SELECT hdemo_sk, hd_income_band_sk FROM common_groups
       )
   GROUP BY c.c_current_hdemo_sk, hd.hd_income_band_sk
)
SELECT
    c_current_hdemo_sk,
    hd_income_band_sk,
    cust_count,
    avg_birth_year,
    total_dep,
    min_last_review,
    max_last_review
FROM agg
WHERE cust_count >= 3
ORDER BY cust_count DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
