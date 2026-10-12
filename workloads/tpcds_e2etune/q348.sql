WITH sales_agg AS (
  SELECT
    s.s_state,
    d.d_year,
    cd.cd_gender,
    ib.ib_income_band_sk,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2018 AND 2022
    AND cd.cd_marital_status = 'M'
    AND s.s_country = 'United States'
    AND s.s_closed_date_sk IS NULL
    AND ib.ib_upper_bound >= 50000
  GROUP BY s.s_state, d.d_year, cd.cd_gender, ib.ib_income_band_sk
)
SELECT
  s_state,
  d_year,
  cd_gender,
  ib_income_band_sk,
  total_sales,
  total_profit,
  avg_discount,
  total_quantity,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_in_year
FROM sales_agg
ORDER BY d_year, sales_rank_in_year
LIMIT 100
