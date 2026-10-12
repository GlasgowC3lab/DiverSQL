WITH sales_month AS (
   SELECT 
      (ss.ss_sold_date_sk / 1000) % 100 AS month,
      ss.ss_net_profit AS net_profit,
      ss.ss_ext_discount_amt AS discount,
      ss.ss_sold_time_sk AS time_sk,
      ss.ss_quantity AS qty
   FROM store_sales ss
   WHERE ss.ss_ext_wholesale_cost IS NOT NULL AND ss.ss_quantity > 1
   UNION ALL
   SELECT 
      (ws.ws_sold_date_sk / 1000) % 100 AS month,
      ws.ws_net_profit AS net_profit,
      ws.ws_ext_discount_amt AS discount,
      ws.ws_sold_time_sk AS time_sk,
      ws.ws_quantity AS qty
   FROM web_sales ws
   WHERE ws.ws_ext_wholesale_cost IS NOT NULL AND ws.ws_quantity > 1
),
monthly_stats AS (
   SELECT
      month,
      AVG(net_profit) AS avg_profit,
      AVG(discount) AS avg_discount,
      SUM(qty) AS total_quantity,
      COUNT(DISTINCT time_sk) AS distinct_time_slots,
      COUNT(*) AS sales_cnt
   FROM sales_month
   GROUP BY month
),
ranked_months AS (
   SELECT
      month,
      avg_profit,
      avg_discount,
      distinct_time_slots,
      total_quantity,
      ROW_NUMBER() OVER (ORDER BY avg_profit DESC) AS rn,
      NTILE(4) OVER (ORDER BY avg_profit) AS profit_quartile,
      PERCENT_RANK() OVER (ORDER BY avg_profit) AS profit_percentile
   FROM monthly_stats
),
top_months AS (
   SELECT month, avg_profit, avg_discount, distinct_time_slots, total_quantity, profit_quartile
   FROM ranked_months
   WHERE profit_quartile = 1
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_credit_rating,
   tm.avg_profit AS birth_month_avg_profit,
   tm.avg_discount AS birth_month_avg_discount,
   tm.distinct_time_slots AS birth_month_time_slots,
   tm.total_quantity AS birth_month_total_qty,
   CASE WHEN c.c_birth_month = tm.month THEN 'BestQuartileProfitMonth' ELSE 'Other' END AS birthday_month_flag,
   ROW_NUMBER() OVER (PARTITION BY tm.month ORDER BY c.c_customer_id) AS row_num_in_month,
   MIN(c.c_login) OVER (PARTITION BY tm.month) AS earliest_login_in_month,
   COUNT(*) OVER (PARTITION BY tm.month) AS customers_in_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN top_months tm ON c.c_birth_month = tm.month
WHERE cd.cd_gender = 'F' AND c.c_email_address LIKE '%@example.com' AND c.c_birth_year >= 1980
ORDER BY tm.avg_profit DESC, c.c_customer_id
LIMIT 25
