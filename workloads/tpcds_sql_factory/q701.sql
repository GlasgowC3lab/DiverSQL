WITH customer_sales AS (SELECT cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk, SUM(cs.cs_net_paid) AS total_net_paid, SUM(cs.cs_coupon_amt) AS total_coupon_amount, SUM(cs.cs_quantity) AS total_quantity FROM catalog_sales cs GROUP BY cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk),
customer_shipmode AS (SELECT cs.cs_bill_customer_sk, cs.cs_ship_mode_sk, COUNT(*) AS mode_count FROM catalog_sales cs GROUP BY cs.cs_bill_customer_sk, cs.cs_ship_mode_sk),
customer_returns AS (SELECT cs.cs_bill_customer_sk, SUM(sr.sr_return_amt_inc_tax) AS total_return_amount, SUM(sr.sr_return_quantity) AS total_return_quantity FROM store_returns sr JOIN catalog_sales cs ON sr.sr_cdemo_sk = cs.cs_bill_cdemo_sk AND sr.sr_item_sk = cs.cs_item_sk GROUP BY cs.cs_bill_customer_sk),
ranked_customers AS (SELECT cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk, cs.total_net_paid, cs.total_coupon_amount, cs.total_quantity, COALESCE(cr.total_return_amount,0) AS total_return_amount, COALESCE(cr.total_return_quantity,0) AS total_return_quantity,
       ROW_NUMBER() OVER (ORDER BY cs.total_net_paid DESC) AS net_paid_rank,
       SUM(cs.total_net_paid) OVER (ORDER BY cs.total_net_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid,
       AVG(cs.total_quantity) OVER () AS avg_quantity_all_customers
FROM customer_sales cs LEFT JOIN customer_returns cr ON cs.cs_bill_customer_sk = cr.cs_bill_customer_sk)
SELECT rc.cs_bill_customer_sk,
       cd.cd_gender,
       cd.cd_credit_rating,
       rc.total_net_paid,
       rc.total_coupon_amount,
       CASE WHEN rc.total_net_paid = 0 THEN 0 ELSE rc.total_coupon_amount / rc.total_net_paid END AS coupon_usage_ratio,
       rc.total_quantity,
       rc.total_return_amount,
       rc.total_return_quantity,
       sm.sm_type AS top_ship_mode_type,
       sm.sm_carrier AS top_ship_mode_carrier,
       rc.net_paid_rank,
       rc.running_total_net_paid,
       ROUND(rc.total_net_paid / SUM(rc.total_net_paid) OVER () * 100, 2) AS pct_of_total_net_paid,
       rc.avg_quantity_all_customers
FROM ranked_customers rc
JOIN customer_demographics cd ON rc.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT cs.cs_bill_customer_sk, cs.cs_ship_mode_sk, ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.mode_count DESC) AS mode_rank
    FROM customer_shipmode cs
) top_mode ON rc.cs_bill_customer_sk = top_mode.cs_bill_customer_sk AND top_mode.mode_rank = 1
LEFT JOIN ship_mode sm ON top_mode.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE rc.net_paid_rank <= 10
ORDER BY rc.net_paid_rank
