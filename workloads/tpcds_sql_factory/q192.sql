WITH city_income_sales AS (
    SELECT ca.ca_state,
           ca.ca_city,
           ib.ib_income_band_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_ext_tax) AS total_tax
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ca.ca_state, ca.ca_city, ib.ib_income_band_sk
    HAVING COUNT(*) > 50
)
SELECT ca_state,
       ca_city,
       ib_income_band_sk,
       total_sales,
       avg_discount,
       distinct_customers,
       total_quantity,
       total_tax,
       CASE WHEN avg_discount >= 45 THEN 'High Discount'
            WHEN avg_discount >= 20 THEN 'Medium Discount'
            ELSE 'Low Discount' END AS discount_category,
       DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_tax DESC) AS tax_rank_in_state,
       SUM(total_sales) OVER (PARTITION BY ca_state) AS state_sales_total
FROM city_income_sales
WHERE total_quantity BETWEEN 1 AND 1000
ORDER BY ca_state, tax_rank_in_state
LIMIT 20
