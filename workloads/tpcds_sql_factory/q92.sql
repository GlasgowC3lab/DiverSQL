WITH sales_month AS (
   SELECT 
      ((ss.ss_sold_date_sk / 1000) % 100) AS month,
      ss.ss_net_profit - ss.ss_ext_discount_amt AS net_gain,
      ss.ss_quantity AS qty
   FROM store_sales ss
   WHERE ss.ss_quantity > 1
   UNION ALL
   SELECT 
      ((ws.ws_sold_date_sk / 1000) % 100) AS month,
      ws.ws_net_profit - ws.ws_ext_discount_amt AS net_gain,
      ws.ws_quantity AS qty
   FROM web_sales ws
   WHERE ws.ws_quantity > 1
),
monthly_stats AS (
   SELECT
      month,
      SUM(net_gain) AS total_gain,
      AVG(qty) AS avg_qty,
      COUNT(*) AS sales_cnt
   FROM sales_month
   GROUP BY month
),
ranked_months AS (
   SELECT
      month,
      total_gain,
      avg_qty,
      ROW_NUMBER() OVER (ORDER BY total_gain DESC) AS rn,
      CUME_DIST() OVER (ORDER BY total_gain DESC) AS cum_dist
   FROM monthly_stats
),
top_months AS (
   SELECT month, total_gain, avg_qty, cum_dist
   FROM ranked_months
   WHERE cum_dist <= 0.5
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_credit_rating,
   tm.total_gain AS birth_month_total_gain,
   tm.avg_qty AS birth_month_avg_qty,
   CASE WHEN c.c_birth_month = tm.month THEN 'Top50PctGainMonth' ELSE 'Other' END AS birthday_month_flag,
   DENSE_RANK() OVER (PARTITION BY tm.month ORDER BY c.c_customer_id) AS dense_rank_in_month,
   MAX(c.c_last_review_date) OVER (PARTITION BY tm.month) AS latest_review_in_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN top_months tm ON c.c_birth_month = tm.month
WHERE cd.cd_gender = 'M' AND c.c_preferred_cust_flag = 'Y'
ORDER BY tm.total_gain DESC, c.c_customer_id
LIMIT 30
