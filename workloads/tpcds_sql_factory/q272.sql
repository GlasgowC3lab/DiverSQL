WITH sales_month AS (
   SELECT 
      mod(cast(ss.ss_sold_date_sk / 100 as integer), 100) AS month,
      ss.ss_net_profit AS net_profit,
      ss.ss_ext_discount_amt AS discount
   FROM store_sales ss
   UNION ALL
   SELECT 
      mod(cast(ws.ws_sold_date_sk / 100 as integer), 100) AS month,
      ws.ws_net_profit AS net_profit,
      ws.ws_ext_discount_amt AS discount
   FROM web_sales ws
),
monthly_stats AS (
   SELECT
      month,
      SUM(net_profit) AS total_profit,
      AVG(discount) AS avg_discount,
      COUNT(*) AS sales_cnt
   FROM sales_month
   GROUP BY month
),
profit_change AS (
   SELECT
      month,
      total_profit,
      LAG(total_profit) OVER (ORDER BY month) AS prev_total_profit,
      total_profit - LAG(total_profit) OVER (ORDER BY month) AS profit_delta
   FROM monthly_stats
),
significant_months AS (
   SELECT month, total_profit, profit_delta
   FROM profit_change
   WHERE profit_delta IS NOT NULL AND profit_delta > 0 AND profit_delta > 1000
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_credit_rating,
   sm.total_profit AS birth_month_total_profit,
   CASE WHEN c.c_birth_month = sm.month THEN 'ProfitIncreaseMonth' ELSE 'Other' END AS profit_month_flag,
   ROW_NUMBER() OVER (PARTITION BY sm.month ORDER BY c.c_customer_id) AS rn_in_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN significant_months sm ON c.c_birth_month = sm.month
WHERE cd.cd_credit_rating = 'A'
ORDER BY sm.profit_delta DESC, c.c_customer_id
LIMIT 10
