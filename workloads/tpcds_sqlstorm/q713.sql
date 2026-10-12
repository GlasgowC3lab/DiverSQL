WITH all_sales AS (
   SELECT ss.ss_customer_sk AS customer_sk,
          'Store' AS channel,
          ss.ss_net_profit AS net_profit,
          ss.ss_net_paid AS net_paid,
          d.d_date AS sold_date,
          ss.ss_item_sk AS item_sk
   FROM store_sales ss
   LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk

   UNION ALL

   SELECT cs.cs_bill_customer_sk AS customer_sk,
          'Catalog' AS channel,
          cs.cs_net_profit,
          cs.cs_net_paid,
          d.d_date,
          cs.cs_item_sk
   FROM catalog_sales cs
   LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk

   UNION ALL

   SELECT ws.ws_bill_customer_sk AS customer_sk,
          'Web' AS channel,
          ws.ws_net_profit,
          ws.ws_net_paid,
          d.d_date,
          ws.ws_item_sk
   FROM web_sales ws
   LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
customer_aggregates AS (
   SELECT
      customer_sk,
      SUM(net_profit) AS total_net_profit,
      SUM(net_paid) AS total_net_paid,
      MAX(sold_date) AS most_recent_purchase_date,
      COUNT(DISTINCT channel) AS channels_used,
      MAX(CASE WHEN channel = 'Store' THEN 1 ELSE 0 END) AS store_flag,
      MAX(CASE WHEN channel = 'Catalog' THEN 1 ELSE 0 END) AS catalog_flag,
      MAX(CASE WHEN channel = 'Web' THEN 1 ELSE 0 END) AS web_flag
   FROM all_sales
   GROUP BY customer_sk
),
ranked_customers AS (
   SELECT
      ca.customer_sk,
      ca.total_net_profit,
      ca.total_net_paid,
      ca.most_recent_purchase_date,
      ca.channels_used,
      ca.store_flag,
      ca.catalog_flag,
      ca.web_flag,
      RANK() OVER (ORDER BY ca.total_net_profit DESC) AS profit_rank,
      ROW_NUMBER() OVER (PARTITION BY ca.customer_sk ORDER BY ca.most_recent_purchase_date DESC) AS recent_purchase_seq
   FROM customer_aggregates ca
)
SELECT
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   rc.total_net_profit,
   rc.total_net_paid,
   CASE
      WHEN rc.total_net_paid = 0 THEN NULL
      ELSE ROUND(100 * rc.total_net_profit / rc.total_net_paid, 2)
   END AS profit_margin_pct,
   rc.most_recent_purchase_date,
   rc.profit_rank,
   CASE
      WHEN rc.total_net_paid >= 20000 THEN 'VIP'
      WHEN rc.total_net_paid >= 10000 THEN 'Gold'
      WHEN rc.total_net_paid >= 5000 THEN 'Silver'
      WHEN rc.total_net_paid > 0 THEN 'Bronze'
      ELSE 'None'
   END AS spend_category,
   CASE
      WHEN COALESCE(rc.store_flag,0) = 1 AND COALESCE(rc.catalog_flag,0) = 1 AND COALESCE(rc.web_flag,0) = 1 THEN 'All Channels'
      ELSE trim(',' FROM
          CONCAT(
             CASE WHEN COALESCE(rc.store_flag,0) = 0 THEN 'Store,' ELSE '' END,
             CASE WHEN COALESCE(rc.catalog_flag,0) = 0 THEN 'Catalog,' ELSE '' END,
             CASE WHEN COALESCE(rc.web_flag,0) = 0 THEN 'Web,' ELSE '' END
          )
      )
   END AS missing_channels,
   (SELECT a.channel
    FROM all_sales a
    WHERE a.customer_sk = c.c_customer_sk
      AND a.sold_date = rc.most_recent_purchase_date
    ORDER BY a.net_profit DESC
    LIMIT 1) AS most_recent_channel,
   (SELECT COUNT(DISTINCT a.item_sk)
    FROM all_sales a
    WHERE a.customer_sk = c.c_customer_sk) AS distinct_items_purchased
FROM customer c
LEFT JOIN ranked_customers rc ON c.c_customer_sk = rc.customer_sk
WHERE rc.total_net_profit IS NOT NULL
ORDER BY rc.profit_rank
LIMIT 20
