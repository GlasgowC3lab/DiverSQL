WITH sales_month AS (
   SELECT 
      mod(cast(ss.ss_sold_date_sk / 100 as integer), 100) AS month,
      ss.ss_net_profit AS net_profit,
      ss.ss_quantity AS qty,
      ss.ss_sold_date_sk AS date_sk
   FROM store_sales ss
   UNION ALL
   SELECT 
      mod(cast(ws.ws_sold_date_sk / 100 as integer), 100) AS month,
      ws.ws_net_profit AS net_profit,
      ws.ws_quantity AS qty,
      ws.ws_sold_date_sk AS date_sk
   FROM web_sales ws
),
monthly_stats AS (
   SELECT
      month,
      SUM(net_profit) AS total_profit,
      AVG(qty) AS avg_qty,
      COUNT(*) AS sale_days,
      MAX(date_sk) AS last_sale_sk
   FROM sales_month
   GROUP BY month
),
recent_months AS (
   SELECT month, total_profit, avg_qty,
          ROW_NUMBER() OVER (ORDER BY last_sale_sk DESC) AS recent_rank
   FROM monthly_stats
   WHERE total_profit > 0
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_education_status,
   rm.total_profit,
   rm.avg_qty,
   CASE WHEN c.c_birth_month = rm.month THEN 'BirthMonthMatch' ELSE 'NoMatch' END AS match_flag,
   LAG(rm.total_profit) OVER (ORDER BY rm.month) AS prev_month_profit,
   LEAD(rm.total_profit) OVER (ORDER BY rm.month) AS next_month_profit
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN recent_months rm ON c.c_birth_month = rm.month
WHERE rm.recent_rank BETWEEN 1 AND 4
ORDER BY c.c_customer_id
LIMIT 30
