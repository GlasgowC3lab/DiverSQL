WITH city_income_sales AS (
    SELECT ca.ca_state,
           ca.ca_city,
           ib.ib_income_band_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ca.ca_state, ca.ca_city, ib.ib_income_band_sk
    HAVING COUNT(*) > 20
)
SELECT ca_state,
       ca_city,
       ib_income_band_sk,
       total_sales,
       avg_discount,
       distinct_customers,
       total_quantity,
       transaction_count,
       CASE WHEN distinct_customers / NULLIF(transaction_count,0) > 0.5 THEN 'Loyal' ELSE 'Casual' END AS customer_type,
       DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank_state,
       SUM(total_sales) OVER (PARTITION BY ca_state) AS state_total_sales
FROM city_income_sales
WHERE total_sales BETWEEN 5000 AND 200000
ORDER BY ca_state, sales_rank_state DESC
LIMIT 20
