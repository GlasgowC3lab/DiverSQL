WITH sales_month AS (
   SELECT 
      mod(cast(ss.ss_sold_date_sk / 100 as integer), 100) AS month,
      ss.ss_net_profit AS net_profit
   FROM store_sales ss
   UNION ALL
   SELECT 
      mod(cast(ws.ws_sold_date_sk / 100 as integer), 100) AS month,
      ws.ws_net_profit AS net_profit
   FROM web_sales ws
),
monthly_stats AS (
   SELECT
      month,
      AVG(net_profit) AS avg_monthly_profit,
      SUM(net_profit) AS total_monthly_profit,
      COUNT(*) AS sales_cnt
   FROM sales_month
   GROUP BY month
),
ranked_months AS (
   SELECT
      month,
      avg_monthly_profit,
      RANK() OVER (ORDER BY avg_monthly_profit DESC) AS month_rank
   FROM monthly_stats
),
top_months AS (
   SELECT month, avg_monthly_profit
   FROM ranked_months
   WHERE month_rank = 1
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_credit_rating,
   tm.avg_monthly_profit AS birth_month_avg_profit,
   CASE WHEN c.c_birth_month = tm.month THEN 'BirthdayMonthTopSeller' ELSE 'Other' END AS birthday_month_flag,
   ROW_NUMBER() OVER (PARTITION BY tm.month ORDER BY c.c_customer_id) AS row_in_birth_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN top_months tm ON c.c_birth_month = tm.month
ORDER BY tm.avg_monthly_profit DESC, c.c_customer_id
LIMIT 20
