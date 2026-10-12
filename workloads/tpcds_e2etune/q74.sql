WITH agg AS (
    SELECT
        sd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics sd ON ss.ss_cdemo_sk = sd.cd_demo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1967
      AND ss.ss_quantity > 0
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453000
    GROUP BY sd.cd_gender, cd.cd_education_status
    HAVING COUNT(DISTINCT c.c_customer_sk) >= 5
       AND SUM(ss.ss_net_profit) > 10000
)
SELECT
    gender,
    education_status,
    total_net_profit,
    total_net_paid_inc_tax,
    avg_sales_price,
    distinct_customers,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 10
