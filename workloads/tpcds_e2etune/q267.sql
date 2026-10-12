WITH cust_sales AS (
    SELECT
        ss_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_ext_discount_amt) AS total_discount,
        AVG(ss_net_profit) AS avg_profit
    FROM store_sales
    WHERE ss_net_profit > 0
      AND ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ss_customer_sk
)
SELECT
    c.c_birth_year,
    c.c_birth_month,
    COUNT(*) AS num_customers,
    SUM(cs.total_profit) AS agg_total_profit,
    SUM(cs.total_discount) AS agg_total_discount,
    AVG(cs.avg_profit) AS avg_profit_per_customer,
    RANK() OVER (ORDER BY SUM(cs.total_profit) DESC) AS profit_rank
FROM cust_sales cs
JOIN customer c
    ON cs.ss_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND c.c_email_address LIKE '%@%.com'
GROUP BY c.c_birth_year, c.c_birth_month
HAVING SUM(cs.total_profit) > 10000
ORDER BY profit_rank
LIMIT 5
