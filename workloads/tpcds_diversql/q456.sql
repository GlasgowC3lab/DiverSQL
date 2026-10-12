WITH cust_addr AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       c.c_preferred_cust_flag,
       ca.ca_state,
       ca.ca_zip,
       c.c_current_cdemo_sk,
       c.c_current_hdemo_sk,
       c.c_current_addr_sk
   FROM customer c
   FULL OUTER JOIN customer_address ca
       ON c.c_current_addr_sk = ca.ca_address_sk
),
returns_agg AS (
   SELECT
       caa.c_customer_id AS customer_id,
       caa.ca_state,
       caa.ca_zip,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       SUM(wr.wr_return_amt) AS total_return_amt,
       COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN cust_addr caa
       ON wr.wr_refunded_customer_sk = caa.c_customer_sk
   LEFT JOIN customer_demographics cd
       ON caa.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN household_demographics hd
       ON caa.c_current_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cd.cd_gender = 'M'
     AND cd.cd_education_status = 'College'
     AND wr.wr_return_amt > 0
     AND wr.wr_return_quantity > 0
   GROUP BY caa.c_customer_id, caa.ca_state, caa.ca_zip,
            hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound

   UNION

   SELECT
       caa.c_customer_id,
       caa.ca_state,
       caa.ca_zip,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       SUM(wr.wr_return_amt),
       COUNT(*)
   FROM web_returns wr
   JOIN cust_addr caa
       ON wr.wr_returning_customer_sk = caa.c_customer_sk
   LEFT JOIN customer_demographics cd
       ON caa.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN household_demographics hd
       ON caa.c_current_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cd.cd_gender = 'M'
     AND cd.cd_education_status = 'College'
     AND wr.wr_return_amt > 0
     AND wr.wr_return_quantity > 0
   GROUP BY caa.c_customer_id, caa.ca_state, caa.ca_zip,
            hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
state_income_agg AS (
   SELECT
       ca_state AS state,
       ib_upper_bound AS income_band_upper,
       SUM(total_return_amt) AS total_return_amt,
       SUM(return_cnt) AS total_returns,
       ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(total_return_amt) DESC) AS rn
   FROM returns_agg
   WHERE ib_upper_bound >= 50000
     AND ca_state IN ('CA','TX','NY','FL')
   GROUP BY ca_state, ib_upper_bound
   HAVING SUM(total_return_amt) > (
       SELECT 0.1 * total_all
       FROM (SELECT SUM(total_return_amt) AS total_all FROM returns_agg) t
   )
)
SELECT
   state,
   income_band_upper,
   total_return_amt,
   total_returns,
   rn
FROM state_income_agg
ORDER BY total_return_amt DESC, state
