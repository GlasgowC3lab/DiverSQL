WITH sales_data AS (
   SELECT
       ss.ss_sold_date_sk      AS date_sk,
       ss.ss_sold_time_sk      AS time_sk,
       ss.ss_cdemo_sk          AS cdemo_sk,
       cd.cd_gender,
       cd.cd_marital_status,
       hd.hd_income_band_sk,
       ss.ss_ext_sales_price   AS ext_sales_price,
       ss.ss_net_profit        AS net_profit,
       t.t_shift,
       t.t_am_pm
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
   WHERE ss.ss_quantity > 2
     AND cd.cd_gender = 'F'
     AND cd.cd_marital_status = 'S'
     AND hd.hd_income_band_sk = 9
     AND t.t_am_pm = 'PM'
     AND ss.ss_cdemo_sk IN (
         SELECT cd_demo_sk
         FROM customer_demographics
         WHERE cd_education_status = 'College'
     )
),
returns_data AS (
   SELECT
       wr.wr_returned_date_sk AS date_sk,
       wr.wr_returned_time_sk AS time_sk,
       wr.wr_refunded_cdemo_sk AS cdemo_sk,
       cd.cd_gender,
       cd.cd_marital_status,
       hd.hd_income_band_sk,
       -wr.wr_return_amt      AS ext_sales_price,
       -wr.wr_net_loss        AS net_profit,
       t.t_shift,
       t.t_am_pm
   FROM web_returns wr
   JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN time_dim t               ON wr.wr_returned_time_sk = t.t_time_sk
   WHERE wr.wr_return_quantity > 0
     AND cd.cd_gender = 'F'
     AND cd.cd_marital_status = 'S'
     AND hd.hd_income_band_sk = 9
     AND t.t_am_pm = 'PM'
),
combined AS (
   SELECT
       date_sk,
       time_sk,
       cdemo_sk,
       cd_gender,
       cd_marital_status,
       hd_income_band_sk,
       ext_sales_price,
       net_profit,
       t_shift,
       t_am_pm,
       'sale'   AS source
   FROM sales_data
   UNION DISTINCT
   SELECT
       date_sk,
       time_sk,
       cdemo_sk,
       cd_gender,
       cd_marital_status,
       hd_income_band_sk,
       ext_sales_price,
       net_profit,
       t_shift,
       t_am_pm,
       'return' AS source
   FROM returns_data
)
SELECT
   cdemo_sk,
   cd_gender,
   cd_marital_status,
   hd_income_band_sk,
   source,
   SUM(ext_sales_price) AS total_amount,
   SUM(net_profit)       AS total_profit,
   RANK() OVER (PARTITION BY source ORDER BY SUM(ext_sales_price) DESC) AS sales_rank,
   CASE WHEN SUM(ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS tier
FROM combined
GROUP BY cdemo_sk, cd_gender, cd_marital_status, hd_income_band_sk, source
ORDER BY source, sales_rank
LIMIT 100
