WITH cust_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS actual_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE cd.cd_credit_rating IN ('A', 'B')
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    cd_purchase_estimate,
    actual_sales,
    total_profit,
    CASE
        WHEN actual_sales > cd_purchase_estimate * 1.2 THEN 'OVERACHIEVER'
        WHEN actual_sales < cd_purchase_estimate * 0.8 THEN 'UNDERACHIEVER'
        ELSE 'ON_TARGET'
    END AS performance_category,
    ROW_NUMBER() OVER (ORDER BY ABS(actual_sales - cd_purchase_estimate) DESC) AS deviation_rank
FROM cust_sales
WHERE actual_sales > 0
ORDER BY deviation_rank
LIMIT 15
