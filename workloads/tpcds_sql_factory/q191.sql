WITH city_income_sales AS (
    SELECT ca.ca_state,
           ca.ca_city,
           ib.ib_income_band_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
           SUM(ss.ss_quantity) AS total_quantity,
           MAX(ss.ss_net_profit) AS max_profit
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
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
       max_profit,
       CASE WHEN avg_discount > 60 THEN 'Very High Discount'
            WHEN avg_discount > 30 THEN 'High Discount'
            WHEN avg_discount > 10 THEN 'Medium Discount'
            ELSE 'Low Discount' END AS discount_category,
       DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS city_sales_rank_in_state,
       ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY max_profit DESC) AS profit_rank_in_state
FROM city_income_sales
WHERE total_quantity >= 5
ORDER BY ca_state, city_sales_rank_in_state
LIMIT 20
