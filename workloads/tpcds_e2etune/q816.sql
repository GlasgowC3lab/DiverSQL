SELECT
    s.s_store_id,
    s.s_city,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    SUM(CASE WHEN hd.hd_vehicle_count > 0 THEN 1 ELSE 0 END) AS households_with_vehicle,
    SUM(hd.hd_dep_count) AS total_dependents
FROM store_sales ss
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
  AND s.s_state = 'CA'
GROUP BY s.s_store_id, s.s_city, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
