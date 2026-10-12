WITH demo_profit AS (
    SELECT
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(CASE WHEN td.t_shift = 'Morning' THEN ss.ss_quantity ELSE 0 END) AS morning_quantity,
        COUNT(DISTINCT CASE WHEN c.c_preferred_cust_flag = 'Y' THEN c.c_customer_id END) AS preferred_customers
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY cd.cd_marital_status, cd.cd_gender, cd.cd_credit_rating
)
SELECT
    dp.cd_marital_status,
    dp.cd_gender,
    dp.cd_credit_rating,
    dp.total_net_profit,
    dp.avg_net_profit,
    dp.total_quantity,
    dp.distinct_customers,
    dp.morning_quantity,
    ROUND(dp.morning_quantity * 100.0 / dp.total_quantity, 2) AS morning_qty_pct,
    dp.preferred_customers,
    PERCENT_RANK() OVER (ORDER BY dp.total_net_profit) AS profit_percentile,
    CASE
        WHEN dp.cd_credit_rating IN ('Excellent', 'Good') THEN 'High Credit'
        WHEN dp.cd_credit_rating = 'Fair' THEN 'Medium Credit'
        ELSE 'Low Credit'
    END AS credit_category,
    RANK() OVER (PARTITION BY dp.cd_marital_status ORDER BY dp.total_quantity DESC) AS qty_rank_within_marital_status
FROM demo_profit dp
WHERE dp.total_quantity > 0
ORDER BY dp.total_net_profit DESC
