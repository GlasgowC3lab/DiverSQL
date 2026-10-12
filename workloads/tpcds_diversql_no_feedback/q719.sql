WITH sales_agg AS (
    SELECT
        ss_customer_sk,
        ss_addr_sk,
        COUNT(*) AS sales_cnt,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount,
        MAX(ss_net_profit) AS max_profit
    FROM store_sales
    WHERE ss_list_price > 60
      AND ss_ext_sales_price > 1000
      AND ss_wholesale_cost < 50
    GROUP BY ss_customer_sk, ss_addr_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_salutation,
    c.c_last_review_date,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    sa.sales_cnt,
    sa.total_sales,
    sa.avg_discount,
    sa.max_profit,
    COUNT(DISTINCT c.c_customer_sk) OVER ()               AS distinct_customer_count,
    SUM(DISTINCT sa.total_sales) OVER ()                 AS distinct_total_sales_sum,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY sa.total_sales DESC) AS state_sales_rank
FROM sales_agg sa
JOIN customer c
    ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON sa.ss_addr_sk = ca.ca_address_sk
   AND c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_zip IN ('40587', '98579', '77752')
  AND ca.ca_street_type = 'Avenue'
  AND c.c_salutation = 'Mrs.'
ORDER BY sa.total_sales DESC, c.c_customer_id
LIMIT 100
