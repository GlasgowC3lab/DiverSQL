WITH
all_sales AS (
 SELECT cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_quantity AS qty,
        i.i_category,
        i.i_category_id
 FROM catalog_sales cs
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2000
 UNION ALL
 SELECT ss.ss_customer_sk AS cust_sk,
        ss.ss_quantity AS qty,
        i.i_category,
        i.i_category_id
 FROM store_sales ss
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2000
 UNION ALL
 SELECT ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_quantity AS qty,
        i.i_category,
        i.i_category_id
 FROM web_sales ws
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2000
),
category_agg AS (
 SELECT cust_sk, i_category, SUM(qty) AS total_qty
 FROM all_sales
 GROUP BY cust_sk, i_category
),
top_category AS (
 SELECT cust_sk,
        i_category AS top_category,
        total_qty
 FROM (
   SELECT cust_sk,
          i_category,
          total_qty,
          ROW_NUMBER() OVER (PARTITION BY cust_sk ORDER BY total_qty DESC, i_category) AS rn
   FROM category_agg
 ) t
 WHERE rn = 1
),
catalog_agg AS (
 SELECT cs.cs_bill_customer_sk AS cust_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        COUNT(*) AS catalog_orders
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2000
 GROUP BY cs.cs_bill_customer_sk
),
store_agg AS (
 SELECT ss.ss_customer_sk AS cust_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(*) AS store_orders
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2000
 GROUP BY ss.ss_customer_sk
),
web_agg AS (
 SELECT ws.ws_bill_customer_sk AS cust_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(*) AS web_orders
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2000
 GROUP BY ws.ws_bill_customer_sk
),
combined_sales AS (
 SELECT
   ids.cust_sk,
   COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
   COALESCE(s.store_net_profit, 0) AS store_net_profit,
   COALESCE(w.web_net_profit, 0) AS web_net_profit,
   COALESCE(c.catalog_quantity, 0) AS catalog_quantity,
   COALESCE(s.store_quantity, 0) AS store_quantity,
   COALESCE(w.web_quantity, 0) AS web_quantity,
   COALESCE(c.catalog_orders, 0) AS catalog_orders,
   COALESCE(s.store_orders, 0) AS store_orders,
   COALESCE(w.web_orders, 0) AS web_orders
 FROM (
   SELECT cust_sk FROM catalog_agg
   UNION
   SELECT cust_sk FROM store_agg
   UNION
   SELECT cust_sk FROM web_agg
 ) ids
 LEFT JOIN catalog_agg c ON ids.cust_sk = c.cust_sk
 LEFT JOIN store_agg s ON ids.cust_sk = s.cust_sk
 LEFT JOIN web_agg w ON ids.cust_sk = w.cust_sk
),
returns_flag AS (
 SELECT cust_sk,
        CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS has_return
 FROM (
   SELECT cr.cr_returning_customer_sk AS cust_sk FROM catalog_returns cr
   UNION ALL
   SELECT sr.sr_customer_sk AS cust_sk FROM store_returns sr
   UNION ALL
   SELECT wr.wr_returning_customer_sk AS cust_sk FROM web_returns wr
 ) all_ret
 GROUP BY cust_sk
),
catalog_top AS (
 SELECT cust_sk,
        catalog_net_profit,
        ROW_NUMBER() OVER (ORDER BY catalog_net_profit DESC) AS rank
 FROM combined_sales
 WHERE catalog_net_profit > 0
),
store_top AS (
 SELECT cust_sk,
        store_net_profit,
        ROW_NUMBER() OVER (ORDER BY store_net_profit DESC) AS rank
 FROM combined_sales
 WHERE store_net_profit > 0
),
web_top AS (
 SELECT cust_sk,
        web_net_profit,
        ROW_NUMBER() OVER (ORDER BY web_net_profit DESC) AS rank
 FROM combined_sales
 WHERE web_net_profit > 0
),
top_channel_sales AS (
 SELECT cust_sk, 'catalog' AS channel, catalog_net_profit AS net_profit, rank
 FROM catalog_top
 WHERE rank <= 5
 UNION ALL
 SELECT cust_sk, 'store' AS channel, store_net_profit AS net_profit, rank
 FROM store_top
 WHERE rank <= 5
 UNION ALL
 SELECT cust_sk, 'web' AS channel, web_net_profit AS net_profit, rank
 FROM web_top
 WHERE rank <= 5
)
SELECT
   c.c_customer_sk,
   COALESCE(c.c_customer_id, 'UNKNOWN') AS customer_id,
   CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name,
   CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS customer_status,
   t.channel,
   t.net_profit,
   t.rank,
   COALESCE(rf.has_return, 0) AS has_return,
   COALESCE(tc.top_category, 'N/A') AS top_category,
   COALESCE(tc.total_qty, 0) AS top_category_qty,
   (SELECT i.i_brand
      FROM catalog_sales cs
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      WHERE cs.cs_bill_customer_sk = c.c_customer_sk
      ORDER BY cs.cs_quantity DESC
      LIMIT 1) AS favorite_brand,
   CASE WHEN COALESCE(rf.has_return,0) = 1 THEN t.net_profit * 0.9 ELSE t.net_profit END AS adjusted_net_profit
FROM top_channel_sales t
LEFT JOIN customer c ON t.cust_sk = c.c_customer_sk
LEFT JOIN top_category tc ON t.cust_sk = tc.cust_sk
LEFT JOIN returns_flag rf ON t.cust_sk = rf.cust_sk
WHERE (c.c_birth_year IS NOT NULL AND c.c_birth_year >= 1950)
  AND COALESCE(c.c_birth_country, '') <> 'United States'
  AND c.c_email_address LIKE '%@%'
  AND c.c_preferred_cust_flag IS NOT NULL
ORDER BY t.channel, t.rank
