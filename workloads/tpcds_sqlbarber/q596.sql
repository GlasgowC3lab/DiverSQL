SELECT c.c_customer_id,
       ib.ib_income_band_sk,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       (SELECT ib2.ib_upper_bound FROM income_band ib2 WHERE ib2.ib_income_band_sk = ib.ib_income_band_sk) AS upper_bound
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450925 AND 2451476
GROUP BY c.c_customer_id, ib.ib_income_band_sk
HAVING COUNT(*) > 2450872
