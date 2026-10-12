WITH
  store_data AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      sr.sr_returned_date_sk,
      sr.sr_return_amt,
      c.c_customer_sk,
      c.c_birth_country,
      cd.cd_gender,
      cd.cd_education_status,
      hd.hd_buy_potential,
      d.d_year
    FROM store s
    JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_state = 'CA'
      AND d.d_year = 2001
      AND c.c_birth_country = 'CAYMAN ISLANDS'
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential = '>10000'
      AND sr.sr_return_amt > 100
  ),
  web_data AS (
    SELECT
      ws.web_site_sk,
      ws.web_name,
      ws.web_class,
      wr.wr_returned_date_sk,
      wr.wr_return_amt,
      c.c_customer_sk,
      cd.cd_gender,
      cd.cd_education_status,
      hd.hd_buy_potential,
      d.d_year
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE ws.web_class = 'Retail'
      AND d.d_year = 2001
      AND c.c_birth_country = 'CAYMAN ISLANDS'
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential = '>10000'
      AND wr.wr_return_amt > 100
  ),
  intersect_customers AS (
    SELECT c_customer_sk FROM store_data
    INTERSECT
    SELECT c_customer_sk FROM web_data
  )
SELECT
  COALESCE(sd.s_store_sk, wd.web_site_sk)               AS entity_id,
  COALESCE(sd.s_store_name, wd.web_name)               AS entity_name,
  COALESCE(sd.s_state, wd.web_class)                  AS entity_type,
  COALESCE(sd.d_year, wd.d_year)                      AS year,
  COALESCE(sd.sr_return_amt, 0)                       AS store_return_amt,
  COALESCE(wd.wr_return_amt, 0)                       AS web_return_amt,
  (COALESCE(sd.sr_return_amt, 0) + COALESCE(wd.wr_return_amt, 0)) AS total_return_amt,
  ROW_NUMBER() OVER (
    PARTITION BY COALESCE(sd.d_year, wd.d_year)
    ORDER BY (COALESCE(sd.sr_return_amt, 0) + COALESCE(wd.wr_return_amt, 0)) DESC
  )                                                    AS rn,
  RANK() OVER (
    PARTITION BY COALESCE(sd.d_year, wd.d_year)
    ORDER BY (COALESCE(sd.sr_return_amt, 0) + COALESCE(wd.wr_return_amt, 0)) DESC
  )                                                    AS rnk
FROM store_data sd
FULL OUTER JOIN web_data wd
  ON sd.sr_returned_date_sk = wd.wr_returned_date_sk
WHERE (
        sd.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
     OR wd.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
      )
  AND (sd.sr_return_amt IS NOT NULL OR wd.wr_return_amt IS NOT NULL)
ORDER BY total_return_amt DESC
LIMIT 100
