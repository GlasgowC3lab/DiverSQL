WITH all_sales AS (
   SELECT
     ss.ss_customer_sk AS customer_sk,
     ss.ss_sold_date_sk AS sold_date_sk,
     ss.ss_net_paid AS net_paid,
     ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
     ss.ss_net_profit AS profit,
     ss.ss_quantity AS quantity,
     'store' AS channel
   FROM store_sales ss
   UNION ALL
   SELECT
     cs.cs_bill_customer_sk AS customer_sk,
     cs.cs_sold_date_sk AS sold_date_sk,
     cs.cs_net_paid AS net_paid,
     cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
     cs.cs_net_profit AS profit,
     cs.cs_quantity AS quantity,
     'catalog' AS channel
   FROM catalog_sales cs
   UNION ALL
   SELECT
     ws.ws_bill_customer_sk AS customer_sk,
     ws.ws_sold_date_sk AS sold_date_sk,
     ws.ws_net_paid AS net_paid,
     ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
     ws.ws_net_profit AS profit,
     ws.ws_quantity AS quantity,
     'web' AS channel
   FROM web_sales ws
),
sales_agg AS (
   SELECT
     a.customer_sk,
     COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_name,
     MIN(d.d_date) AS first_purchase_date,
     MAX(d.d_date) AS last_purchase_date,
     SUM(a.net_paid) AS total_net_paid,
     SUM(a.net_paid_inc_tax) AS total_net_paid_inc_tax,
     SUM(a.profit) AS total_profit,
     COUNT(*) AS total_transactions,
     COUNT(DISTINCT a.channel) AS channels_used,
     SUM(CASE WHEN a.channel = 'store' THEN a.net_paid END) AS store_net_paid,
     SUM(CASE WHEN a.channel = 'catalog' THEN a.net_paid END) AS catalog_net_paid,
     SUM(CASE WHEN a.channel = 'web' THEN a.net_paid END) AS web_net_paid,
     MAX(CASE WHEN a.channel = 'store' THEN a.net_paid END) AS max_store_net_paid,
     MAX(CASE WHEN a.channel = 'catalog' THEN a.net_paid END) AS max_catalog_net_paid,
     MAX(CASE WHEN a.channel = 'web' THEN a.net_paid END) AS max_web_net_paid,
     SUM(CASE WHEN a.net_paid > 0 THEN a.net_paid ELSE 0 END) AS positive_net_paid,
     SUM(CASE WHEN a.net_paid < 0 THEN a.net_paid ELSE 0 END) AS negative_net_paid
   FROM all_sales a
   LEFT JOIN date_dim d ON a.sold_date_sk = d.d_date_sk
   LEFT JOIN customer c ON a.customer_sk = c.c_customer_sk
   GROUP BY a.customer_sk, c.c_first_name, c.c_last_name
),
ranked_customers AS (
   SELECT
     *,
     ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS revenue_rank,
     NTILE(10) OVER (ORDER BY total_net_paid DESC) AS revenue_decile,
     CASE 
        WHEN total_profit / NULLIF(total_net_paid, 0) > 0.2 THEN 'HIGH'
        WHEN total_profit / NULLIF(total_net_paid, 0) > 0.1 THEN 'MEDIUM'
        ELSE 'LOW'
     END AS profit_category,
     CAST(ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS VARCHAR) || ': ' || COALESCE(customer_name, 'Unknown') AS rank_label
   FROM sales_agg
),
customer_address_info AS (
   SELECT
     rc.customer_sk,
     ca.ca_city,
     ca.ca_state,
     ca.ca_country,
     ca.ca_zip,
     ca.ca_gmt_offset,
     CASE WHEN ca.ca_country = 'United States' THEN 'Domestic' ELSE 'International' END AS market_region
   FROM ranked_customers rc
   LEFT JOIN customer c ON rc.customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
  rc.revenue_rank,
  rc.rank_label,
  rc.customer_name,
  rc.total_net_paid,
  rc.total_net_paid_inc_tax,
  rc.total_profit,
  rc.profit_category,
  rc.first_purchase_date,
  rc.last_purchase_date,
  rc.channels_used,
  rc.store_net_paid,
  rc.catalog_net_paid,
  rc.web_net_paid,
  rc.max_store_net_paid,
  rc.max_catalog_net_paid,
  rc.max_web_net_paid,
  ci.ca_city,
  ci.ca_state,
  ci.ca_country,
  ci.market_region,
  (SELECT COUNT(DISTINCT d2.d_date) 
   FROM all_sales a2 
   JOIN date_dim d2 ON a2.sold_date_sk = d2.d_date_sk 
   WHERE a2.customer_sk = rc.customer_sk) AS distinct_purchase_days,
  rc.total_net_paid / NULLIF(date_diff('day', rc.first_purchase_date, rc.last_purchase_date) + 1, 0) AS avg_daily_net_paid,
  CONCAT(rc.rank_label, ' - ', rc.profit_category, ' profit, ', CAST(rc.total_net_paid AS VARCHAR), ' USD') AS description,
  CASE 
    WHEN rc.revenue_rank <= 10 THEN 'Top10'
    WHEN rc.revenue_rank <= 100 THEN 'Top100'
    ELSE 'Other'
  END AS tier
FROM ranked_customers rc
LEFT OUTER JOIN customer_address_info ci ON rc.customer_sk = ci.customer_sk
WHERE rc.revenue_rank <= 1000
ORDER BY rc.revenue_rank
LIMIT 500
