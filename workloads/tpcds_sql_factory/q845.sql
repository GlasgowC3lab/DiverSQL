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
   SELECT month,
          SUM(net_profit) AS total_profit,
          SUM(qty) AS total_qty,
          MAX(date_sk) AS last_sale_sk
   FROM sales_month
   GROUP BY month
),
recent_months AS (
   SELECT month, total_profit, total_qty,
          ROW_NUMBER() OVER (ORDER BY last_sale_sk DESC) AS recent_rank,
          PERCENT_RANK() OVER (ORDER BY total_profit) AS profit_percentile
   FROM monthly_stats
)
SELECT 
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   cd.cd_education_status,
   rm.month,
   rm.total_profit,
   rm.total_qty,
   CASE WHEN rm.profit_percentile < 0.25 THEN 'LowProfit' WHEN rm.profit_percentile < 0.75 THEN 'MidProfit' ELSE 'HighProfit' END AS profit_category,
   COUNT(*) OVER (PARTITION BY rm.month) AS customers_in_month
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN recent_months rm ON c.c_birth_month = rm.month
WHERE rm.recent_rank <= 6
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_education_status, rm.month, rm.total_profit, rm.total_qty, rm.profit_percentile
ORDER BY rm.total_profit DESC
LIMIT 30
