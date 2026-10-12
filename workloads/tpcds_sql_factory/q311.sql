WITH store_agg AS (
   SELECT ss_customer_sk,
          SUM(ss_net_profit) AS store_net_profit,
          COUNT(*) AS store_sales_cnt
   FROM store_sales
   GROUP BY ss_customer_sk
),
web_agg AS (
   SELECT ws_bill_customer_sk,
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
          COALESCE(sa.store_sales_cnt, 0) + COALESCE(wa.web_sales_cnt, 0) AS total_sales_cnt,
          CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 1 ELSE 0 END AS is_excellent_credit
   FROM customer c
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN store_agg sa ON c.c_customer_sk = sa.ss_customer_sk
   LEFT JOIN web_agg wa ON c.c_customer_sk = wa.ws_bill_customer_sk
)
SELECT
   ct.c_customer_id,
   ct.c_first_name,
   ct.c_last_name,
   ct.c_birth_month,
   ct.cd_gender,
   ct.total_net_profit,
   ct.total_sales_cnt,
   ct.is_excellent_credit,
   RANK() OVER (ORDER BY ct.total_net_profit DESC) AS global_profit_rank,
   CASE 
      WHEN ct.total_net_profit > 20000 THEN 'Diamond'
      WHEN ct.total_net_profit > 10000 THEN 'Platinum'
      WHEN ct.total_net_profit > 5000 THEN 'Gold'
      ELSE 'Silver'
   END AS tier_label,
   CASE 
      WHEN ct.is_excellent_credit = 1 AND ct.total_sales_cnt > 20 THEN 'Prime'
      ELSE 'Standard'
   END AS segment
FROM customer_total ct
WHERE ct.total_sales_cnt >= 3 AND ct.total_net_profit > 0
ORDER BY ct.total_net_profit DESC, ct.total_sales_cnt ASC
LIMIT 25
