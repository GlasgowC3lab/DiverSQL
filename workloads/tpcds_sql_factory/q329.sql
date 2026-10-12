WITH sales_month AS (
   SELECT 
      ((ss.ss_sold_date_sk / 1000) % 100) AS month,
      ss.ss_net_profit - ss.ss_ext_discount_amt AS net_gain,
      ss.ss_sold_time_sk AS time_sk
   FROM store_sales ss
   WHERE ss.ss_ext_wholesale_cost IS NOT NULL AND ss.ss_net_profit > 0
   UNION ALL
   SELECT 
      ((ws.ws_sold_date_sk / 1000) % 100) AS month,
      ws.ws_net_profit - ws.ws_ext_discount_amt AS net_gain,
      ws.ws_sold_time_sk AS time_sk
   FROM web_sales ws
   WHERE ws.ws_ext_wholesale_cost IS NOT NULL AND ws.ws_net_profit > 0
),
monthly_stats AS (
   SELECT
      month,
      SUM(net_gain) AS total_gain,
      AVG(net_gain) AS avg_gain,
      COUNT(*) AS sales_cnt,
      COUNT(DISTINCT time_sk) AS distinct_time_slots
   FROM sales_month
   GROUP BY month
),
ranked_months AS (
   SELECT
      month,
      total_gain,
      avg_gain,
      distinct_time_slots,
      ROW_NUMBER() OVER (ORDER BY total_gain DESC) AS rn,
      NTILE(5) OVER (ORDER BY total_gain) AS gain_quintile
   FROM monthly_stats
),
selected_months AS (
   SELECT month, total_gain, avg_gain, distinct_time_slots
   FROM ranked_months
   WHERE gain_quintile = 5
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_credit_rating,
   sm.total_gain AS birth_month_total_gain,
   sm.avg_gain AS birth_month_avg_gain,
   sm.distinct_time_slots AS birth_month_time_slots,
   CASE WHEN c.c_birth_month = sm.month THEN 'TopGainMonth' ELSE 'Other' END AS birthday_month_flag,
   ROW_NUMBER() OVER (PARTITION BY sm.month ORDER BY c.c_customer_id) AS row_num_in_month,
   MAX(c.c_login) OVER (PARTITION BY sm.month) AS latest_login_in_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN selected_months sm ON c.c_birth_month = sm.month
WHERE cd.cd_gender = 'F' AND c.c_email_address LIKE '%@example.com' AND c.c_preferred_cust_flag = 'Y'
ORDER BY sm.total_gain DESC, c.c_customer_id
LIMIT 25
