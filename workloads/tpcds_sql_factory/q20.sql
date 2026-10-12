WITH store_agg AS (
   SELECT ss_customer_sk AS c_customer_sk,
          SUM(ss_net_profit) AS store_net_profit,
          COUNT(*) AS store_sales_cnt
   FROM store_sales
   GROUP BY ss_customer_sk
),
web_agg AS (
   SELECT ws_bill_customer_sk AS c_customer_sk,
          SUM(ws_net_profit) AS web_net_profit,
          COUNT(*) AS web_sales_cnt
   FROM web_sales
   GROUP BY ws_bill_customer_sk
),
customer_total AS (
   SELECT c.c_customer_sk,
          c.c_customer_id,
          c.c_first_name,
          c.c_last_name,
          c.c_birth_month,
          cd.cd_gender,
          cd.cd_purchase_estimate,
          COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
          COALESCE(sa.store_sales_cnt, 0) + COALESCE(wa.web_sales_cnt, 0) AS total_sales_cnt
   FROM customer c
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store_agg sa ON c.c_customer_sk = sa.c_customer_sk
   LEFT JOIN web_agg wa ON c.c_customer_sk = wa.c_customer_sk
)
SELECT
   c_total.c_customer_id,
   c_total.c_first_name,
   c_total.c_last_name,
   c_total.c_birth_month,
   c_total.cd_gender,
   c_total.total_net_profit,
   RANK() OVER (PARTITION BY c_total.cd_gender ORDER BY c_total.total_net_profit DESC) AS gender_profit_rank,
   CASE 
      WHEN c_total.cd_purchase_estimate >= 5000 THEN 'High'
      WHEN c_total.cd_purchase_estimate BETWEEN 2000 AND 4999 THEN 'Medium'
      ELSE 'Low'
   END AS purchase_estimate_category,
   CASE 
      WHEN c_total.total_net_profit > 10000 THEN 'VIP'
      WHEN c_total.total_net_profit > 5000 THEN 'Gold'
      ELSE 'Silver'
   END AS customer_value_tier
FROM customer_total c_total
WHERE c_total.total_net_profit > 0
ORDER BY c_total.total_net_profit DESC
LIMIT 15
