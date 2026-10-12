WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN td.t_meal_time = 'Lunch' THEN ss.ss_quantity ELSE 0 END) AS lunch_qty,
        SUM(CASE WHEN td.t_meal_time = 'Dinner' THEN ss.ss_quantity ELSE 0 END) AS dinner_qty
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_month
)

SELECT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_birth_month,
    cs.total_net_profit,
    RANK() OVER (PARTITION BY cs.c_birth_month ORDER BY cs.total_net_profit DESC) AS profit_rank_in_month,
    DENSE_RANK() OVER (ORDER BY cs.avg_purchase_estimate DESC) AS purchase_estimate_rank,
    CASE
        WHEN cs.total_net_profit >= 5000 THEN 'Platinum'
        WHEN cs.total_net_profit >= 2000 THEN 'Gold'
        WHEN cs.total_net_profit >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    cs.lunch_qty,
    cs.dinner_qty
FROM customer_sales cs
WHERE cs.total_net_profit > 0
ORDER BY cs.c_birth_month, profit_rank_in_month
