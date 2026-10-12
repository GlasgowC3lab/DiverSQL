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
      SUM(qty) AS total_qty,
      MIN(date_sk) AS first_sale_sk,
      MAX(date_sk) AS last_sale_sk
   FROM sales_month
   GROUP BY month
),
recent_months AS (
   SELECT month, total_profit, total_qty,
          ROW_NUMBER() OVER (ORDER BY last_sale_sk DESC) AS recent_rank
   FROM monthly_stats
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   c.c_birth_month,
   cd.cd_education_status,
   rm.total_profit AS birth_month_total_profit,
   CASE WHEN c.c_birth_month = rm.month THEN 'MostRecentMonth' ELSE 'Other' END AS recent_flag,
   NTILE(4) OVER (ORDER BY rm.total_profit DESC) AS profit_quartile
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN recent_months rm ON c.c_birth_month = rm.month
WHERE rm.recent_rank <= 5
ORDER BY rm.total_profit DESC, c.c_customer_id
LIMIT 30
