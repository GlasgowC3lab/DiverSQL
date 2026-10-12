WITH city_income_sales AS (
    SELECT ca.ca_state,
           ca.ca_city,
           ib.ib_income_band_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(*) FILTER (WHERE ss.ss_net_profit > 0) AS profitable_transactions
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ca.ca_state, ca.ca_city, ib.ib_income_band_sk
)
SELECT ca_state,
       ca_city,
       ib_income_band_sk,
       total_sales,
       avg_discount,
       distinct_customers,
       total_quantity,
       profitable_transactions,
       CASE WHEN avg_discount > 55 THEN 'Very High Discount'
            WHEN avg_discount > 25 THEN 'High Discount'
            WHEN avg_discount > 5 THEN 'Low Discount'
            ELSE 'No Discount' END AS discount_category,
       ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY profitable_transactions DESC) AS profit_txn_rank
FROM city_income_sales
WHERE profitable_transactions > 0
ORDER BY ca_state, profit_txn_rank
LIMIT 20
