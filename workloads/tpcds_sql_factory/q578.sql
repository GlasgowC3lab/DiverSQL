WITH customer_metrics AS (
    SELECT
        cs.cs_bill_customer_sk AS bill_cust_id,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_paid,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS total_orders,
        MAX(d.d_date) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_credit_rating
),
ship_mode_counts AS (
    SELECT
        cs.cs_bill_customer_sk AS bill_cust_id,
        sm.sm_type,
        COUNT(*) AS mode_cnt
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY cs.cs_bill_customer_sk, sm.sm_type
),
customer_ship_mode AS (
    SELECT
        bill_cust_id,
        sm_type,
        ROW_NUMBER() OVER (PARTITION BY bill_cust_id ORDER BY mode_cnt DESC) AS rn
    FROM ship_mode_counts
)
SELECT
    cm.bill_cust_id,
    cm.total_profit,
    cm.total_paid,
    cm.avg_coupon_amount,
    cm.total_quantity,
    cm.total_orders,
    cm.last_purchase_date,
    cm.cd_gender,
    cm.cd_marital_status,
    cm.cd_education_status,
    cm.cd_credit_rating,
    sm.sm_type AS most_frequent_ship_mode,
    DENSE_RANK() OVER (ORDER BY cm.total_profit DESC) AS profit_rank,
    CASE
        WHEN cm.total_profit > 50000 THEN 'Platinum'
        WHEN cm.total_profit > 20000 THEN 'Gold'
        ELSE 'Silver'
    END AS profit_tier
FROM customer_metrics cm
LEFT JOIN customer_ship_mode sm
    ON cm.bill_cust_id = sm.bill_cust_id AND sm.rn = 1
ORDER BY profit_rank
LIMIT 100
