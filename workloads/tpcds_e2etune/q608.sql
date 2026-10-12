WITH cust_income AS (
  SELECT
    c.c_customer_id,
    c.c_birth_country,
    c.c_current_hdemo_sk,
    c.c_current_cdemo_sk,
    c.c_birth_year,
    c.c_preferred_cust_flag,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM customer c
  JOIN income_band ib
    ON c.c_current_hdemo_sk = ib.ib_income_band_sk
  WHERE c.c_birth_year BETWEEN 1950 AND 2000
),
agg AS (
  SELECT
    ws.web_site_id,
    ws.web_name,
    ci.ib_income_band_sk,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    COUNT(DISTINCT ci.c_customer_id) AS num_customers,
    SUM(CASE WHEN ci.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customers,
    AVG(ci.c_current_cdemo_sk) AS avg_demo_sk
  FROM cust_income ci
  JOIN web_site ws
    ON ci.c_birth_country = ws.web_country
  WHERE ws.web_open_date_sk >= 20000101
  GROUP BY ws.web_site_id, ws.web_name, ci.ib_income_band_sk, ci.ib_lower_bound, ci.ib_upper_bound
  HAVING COUNT(DISTINCT ci.c_customer_id) > 10
)
SELECT
  web_site_id,
  web_name,
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  num_customers,
  preferred_customers,
  avg_demo_sk,
  RANK() OVER (ORDER BY num_customers DESC) AS site_income_rank
FROM agg
ORDER BY num_customers DESC
LIMIT 100
