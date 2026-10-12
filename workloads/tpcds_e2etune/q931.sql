WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        t.t_hour AS t_hour,
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 12 AND 13
      AND ss.ss_ext_discount_amt > 5.00
      AND c.c_salutation IN ('Mr.', 'Mrs.')
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_type = 'product'
      )
    GROUP BY ss.ss_store_sk, t.t_hour, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    store_sk,
    t_hour,
    cd_gender,
    cd_marital_status,
    total_profit,
    avg_discount,
    unique_customers,
    RANK() OVER (PARTITION BY store_sk ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
