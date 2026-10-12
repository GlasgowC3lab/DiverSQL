WITH sales_data AS (
 SELECT d.d_year,
        'store' AS channel,
        s.s_state AS region_state,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 WHERE d.d_year BETWEEN 1998 AND 2000

 UNION ALL

 SELECT d.d_year,
        'catalog' AS channel,
        c.cc_state AS region_state,
        cs.cs_call_center_sk AS store_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
 WHERE d.d_year BETWEEN 1998 AND 2000

 UNION ALL

 SELECT d.d_year,
        'web' AS channel,
        w.web_state AS region_state,
        ws.ws_web_site_sk AS store_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 WHERE d.d_year BETWEEN 1998 AND 2000
),
agg AS (
 SELECT
   channel,
   region_state,
   d_year,
   SUM(quantity) AS total_quantity,
   SUM(net_paid) AS total_net_paid,
   SUM(net_profit) AS total_net_profit,
   COUNT(DISTINCT customer_sk) AS distinct_customers,
   COUNT(DISTINCT item_sk) AS distinct_items,
   AVG(net_paid / NULLIF(quantity, 0)) AS avg_price_per_item
 FROM sales_data
 GROUP BY channel, region_state, d_year
)
SELECT
  channel,
  region_state,
  d_year,
  total_quantity,
  total_net_paid,
  total_net_profit,
  distinct_customers,
  distinct_items,
  avg_price_per_item,
  RANK() OVER (PARTITION BY channel, d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY channel, d_year, profit_rank
