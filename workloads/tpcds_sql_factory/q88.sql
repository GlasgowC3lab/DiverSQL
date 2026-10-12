WITH sales_month AS (
   SELECT 
      (ss.ss_sold_date_sk / 1000) % 100 AS month,
      ss.ss_net_profit AS net_profit,
      ss.ss_ext_discount_amt AS discount
   FROM store_sales ss
   WHERE ss.ss_ext_discount_amt > 0
   UNION ALL
   SELECT 
      (ws.ws_sold_date_sk / 1000) % 100 AS month,
      ws.ws_net_profit AS net_profit,
      ws.ws_ext_discount_amt AS discount
   FROM web_sales ws
   WHERE ws.ws_ext_discount_amt > 0
),
monthly_stats AS (
   SELECT
      month,
      AVG(net_profit) AS avg_monthly_profit,
      AVG(discount) AS avg_discount,
      COUNT(*) AS sales_cnt
   FROM sales_month
   GROUP BY month
),
ranked_months AS (
   SELECT
      month,
      avg_monthly_profit,
      avg_discount,
      ROW_NUMBER() OVER (ORDER BY avg_monthly_profit DESC) AS rn
   FROM monthly_stats
),
top_months AS (
   SELECT month, avg_monthly_profit, avg_discount
   FROM ranked_months
   WHERE rn <= 2
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_credit_rating,
   tm.avg_monthly_profit AS birth_month_avg_profit,
   tm.avg_discount AS birth_month_avg_discount,
   CASE WHEN c.c_birth_month = tm.month THEN 'Top2ProfitMonth' ELSE 'Other' END AS birthday_month_flag,
   DENSE_RANK() OVER (PARTITION BY tm.month ORDER BY c.c_customer_id) AS dense_rank_in_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN top_months tm ON c.c_birth_month = tm.month
WHERE cd.cd_gender = 'M'
ORDER BY tm.avg_monthly_profit DESC, c.c_customer_id
LIMIT 25
