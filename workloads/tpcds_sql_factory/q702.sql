WITH customer_sales AS (SELECT cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk, SUM(cs.cs_net_paid) AS total_net_paid, SUM(cs.cs_coupon_amt) AS total_coupon_amount, SUM(cs.cs_quantity) AS total_quantity FROM catalog_sales cs GROUP BY cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk),
customer_shipmode AS (SELECT cs.cs_bill_customer_sk, cs.cs_ship_mode_sk, COUNT(*) AS mode_count FROM catalog_sales cs GROUP BY cs.cs_bill_customer_sk, cs.cs_ship_mode_sk),
customer_returns AS (SELECT cs.cs_bill_customer_sk, SUM(sr.sr_return_amt_inc_tax) AS total_return_amount, SUM(sr.sr_return_quantity) AS total_return_quantity FROM store_returns sr JOIN catalog_sales cs ON sr.sr_cdemo_sk = cs.cs_bill_cdemo_sk AND sr.sr_item_sk = cs.cs_item_sk GROUP BY cs.cs_bill_customer_sk),
aggregated AS (SELECT cs.cs_bill_customer_sk,
                    cs.cs_bill_cdemo_sk,
                    cs.total_net_paid,
                    cs.total_coupon_amount,
                    cs.total_quantity,
                    COALESCE(cr.total_return_amount,0) AS total_return_amount,
                    COALESCE(cr.total_return_quantity,0) AS total_return_quantity,
                    MAX(cs.total_net_paid) OVER (PARTITION BY cs.cs_bill_cdemo_sk) AS max_net_paid_in_demo,
                    MIN(cs.total_net_paid) OVER (PARTITION BY cs.cs_bill_cdemo_sk) AS min_net_paid_in_demo
             FROM customer_sales cs LEFT JOIN customer_returns cr ON cs.cs_bill_customer_sk = cr.cs_bill_customer_sk)
SELECT a.cs_bill_customer_sk,
       cd.cd_gender,
       cd.cd_credit_rating,
       a.total_net_paid,
       a.total_coupon_amount,
       CASE WHEN a.total_net_paid = 0 THEN 0 ELSE a.total_coupon_amount / a.total_net_paid END AS coupon_usage_ratio,
       a.total_quantity,
       a.total_return_amount,
       a.total_return_quantity,
       sm.sm_type AS top_ship_mode_type,
       sm.sm_carrier AS top_ship_mode_carrier,
       a.max_net_paid_in_demo,
       a.min_net_paid_in_demo,
       ROUND(a.total_net_paid / a.max_net_paid_in_demo * 100, 2) AS pct_of_max_in_demo
FROM aggregated a
JOIN customer_demographics cd ON a.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT cs.cs_bill_customer_sk, cs.cs_ship_mode_sk, ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.mode_count DESC) AS mode_rank
    FROM customer_shipmode cs
) top_mode ON a.cs_bill_customer_sk = top_mode.cs_bill_customer_sk AND top_mode.mode_rank = 1
LEFT JOIN ship_mode sm ON top_mode.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE a.total_net_paid > (SELECT AVG(total_net_paid) FROM aggregated)
ORDER BY a.total_net_paid DESC
LIMIT 15
