WITH customer_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_profit) AS order_profit,
        MAX(cs.cs_promo_sk) AS promo_sk,
        MAX(cs.cs_ship_mode_sk) AS ship_mode_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk, cs.cs_order_number
),
customer_agg AS (
    SELECT
        cs.customer_sk,
        COUNT(*) AS total_orders,
        AVG(cs.order_profit) AS avg_profit_per_order,
        SUM(cs.order_profit) AS total_profit,
        MAX(cs.promo_sk) AS any_promo_sk
    FROM customer_sales cs
    GROUP BY cs.customer_sk
),
customer_primary_ship_mode AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_ship_mode_sk,
        COUNT(*) AS cnt,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY COUNT(*) DESC) AS rn
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk, cs.cs_ship_mode_sk
)
SELECT
    ca.customer_sk,
    ca.total_orders,
    ca.avg_profit_per_order,
    ca.total_profit,
    CASE WHEN ca.any_promo_sk IS NOT NULL THEN 'Yes' ELSE 'No' END AS used_promotion,
    p.p_promo_name,
    sm.sm_type AS most_frequent_ship_mode,
    DENSE_RANK() OVER (ORDER BY ca.total_profit DESC) AS profit_rank,
    CASE
        WHEN ca.total_profit > 500000 THEN 'Platinum'
        WHEN ca.total_profit BETWEEN 200000 AND 500000 THEN 'Gold'
        WHEN ca.total_profit BETWEEN 50000 AND 200000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM customer_agg ca
JOIN customer_primary_ship_mode cpsm ON ca.customer_sk = cpsm.customer_sk AND cpsm.rn = 1
JOIN ship_mode sm ON cpsm.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN promotion p ON ca.any_promo_sk = p.p_promo_sk
ORDER BY ca.total_profit DESC
LIMIT 10
