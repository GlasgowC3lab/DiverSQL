WITH sales_agg AS (
  SELECT
    ss_customer_sk,
    ss_hdemo_sk,
    COUNT(*) AS sales_cnt,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_sales_price) AS avg_sales,
    MAX(ss_ext_sales_price) AS max_sales,
    MIN(ss_ext_sales_price) AS min_sales
  FROM store_sales
  WHERE ss_ext_wholesale_cost > 500.00
    AND ss_list_price BETWEEN 50.00 AND 150.00
    AND ss_quantity >= 1
    AND ss_ext_discount_amt < 200.00
    AND ss_ext_tax BETWEEN 0.00 AND 500.00
    AND ss_coupon_amt = 0.00
  GROUP BY ss_customer_sk, ss_hdemo_sk
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_salutation,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  SUM(sa.total_sales) AS sum_total_sales,
  AVG(sa.avg_sales) AS avg_sales_per_customer,
  COUNT(DISTINCT sa.ss_hdemo_sk) AS distinct_demo_count,
  MAX(sa.max_sales) AS max_single_sale,
  MIN(sa.min_sales) AS min_single_sale
FROM sales_agg sa
JOIN customer c
  ON sa.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE c.c_salutation = 'Mr.'
  AND c.c_birth_year BETWEEN 1970 AND 1990
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_first_shipto_date_sk BETWEEN 2450000 AND 2452000
  AND hd.hd_buy_potential = '1001-5000'
  AND hd.hd_dep_count <= 3
  AND ib.ib_upper_bound <= 50000
  AND EXISTS (
        SELECT 1 FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_ext_sales_price > 1000.00
      )
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  c.c_salutation,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound
HAVING SUM(sa.total_sales) > (
        SELECT AVG(total_sales) FROM sales_agg
      )
ORDER BY sum_total_sales DESC
LIMIT 100
