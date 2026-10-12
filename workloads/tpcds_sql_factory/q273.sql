WITH city_income_sales AS (
    SELECT ca.ca_state,
           ca.ca_city,
           ib.ib_income_band_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ca.ca_state, ca.ca_city, ib.ib_income_band_sk
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT ca_state,
       ca_city,
       ib_income_band_sk,
       total_sales,
       avg_discount,
       distinct_customers,
       total_quantity,
       NTILE(4) OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_quartile,
       CASE WHEN avg_discount > 30 THEN 'High' ELSE 'Normal' END AS discount_flag
FROM city_income_sales
WHERE total_quantity BETWEEN 5 AND 500
ORDER BY ca_state, sales_quartile DESC
LIMIT 25
