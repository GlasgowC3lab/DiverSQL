WITH agg AS (
    SELECT
        cd.cd_education_status AS education_status,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 500
      AND ss.ss_net_profit > 0
      AND ss.ss_coupon_amt > 0
      AND ss.ss_sold_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY cd.cd_education_status, cd.cd_gender
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    education_status,
    gender,
    total_net_profit,
    avg_discount,
    total_quantity,
    distinct_customers,
    RANK() OVER (PARTITION BY education_status ORDER BY total_net_profit DESC) AS profit_rank_by_education
FROM agg
ORDER BY total_net_profit DESC
LIMIT 20
