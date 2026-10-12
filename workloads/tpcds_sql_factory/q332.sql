WITH sales_month AS (
   SELECT 
      (ss.ss_sold_date_sk / 1000) % 100 AS month,
      ss.ss_net_profit,
      ss.ss_ext_discount_amt,
      ss.ss_sold_time_sk,
      DATE_PARSE(CONCAT('20', CAST(ss.ss_sold_date_sk AS VARCHAR)), '%Y%m%d') AS sold_date
   FROM store_sales ss
   WHERE ss.ss_ext_wholesale_cost IS NOT NULL AND ss.ss_net_profit > 0
   UNION ALL
   SELECT 
      (ws.ws_sold_date_sk / 1000) % 100 AS month,
      ws.ws_net_profit,
      ws.ws_ext_discount_amt,
      ws.ws_sold_time_sk,
      DATE_PARSE(CONCAT('20', CAST(ws.ws_sold_date_sk AS VARCHAR)), '%Y%m%d') AS sold_date
   FROM web_sales ws
   WHERE ws.ws_ext_wholesale_cost IS NOT NULL AND ws.ws_net_profit > 0
),
monthly_stats AS (
   SELECT
      month,
      AVG(ss_net_profit) AS avg_profit,
      AVG(ss_ext_discount_amt) AS avg_discount,
      COUNT(DISTINCT ss_sold_time_sk) AS distinct_time_slots,
      COUNT(*) AS sales_cnt,
      MIN(sold_date) AS first_sale_date,
      MAX(sold_date) AS last_sale_date
   FROM sales_month
   GROUP BY month
),
ranked_months AS (
   SELECT
      month,
      avg_profit,
      avg_discount,
      distinct_time_slots,
      ROW_NUMBER() OVER (ORDER BY avg_profit DESC) AS rn,
      NTILE(3) OVER (ORDER BY avg_profit) AS profit_tertile,
      DATE_DIFF('day', first_sale_date, last_sale_date) AS active_days
   FROM monthly_stats
),
selected_months AS (
   SELECT month, avg_profit, avg_discount, distinct_time_slots, active_days
   FROM ranked_months
   WHERE profit_tertile = 1 AND active_days > 30
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_credit_rating,
   sm.avg_profit AS birth_month_avg_profit,
   sm.avg_discount AS birth_month_avg_discount,
   sm.distinct_time_slots AS birth_month_time_slots,
   sm.active_days AS birth_month_active_days,
   CASE WHEN c.c_birth_month = sm.month THEN 'TopTertileActiveMonth' ELSE 'Other' END AS birthday_month_flag,
   ROW_NUMBER() OVER (PARTITION BY sm.month ORDER BY c.c_customer_id) AS row_num_in_month,
   MIN(c.c_login) OVER (PARTITION BY sm.month) AS earliest_login_in_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN selected_months sm ON c.c_birth_month = sm.month
WHERE cd.cd_gender = 'F' AND c.c_email_address LIKE '%@example.com' AND cd.cd_credit_rating IN ('A', 'B')
ORDER BY sm.avg_profit DESC, c.c_customer_id
LIMIT 25
