WITH combined_sales AS (
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_call_center_sk AS cc_sk,
          CAST(NULL AS integer) AS store_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_quantity AS quantity,
          cs.cs_net_paid AS net_paid,
          cs.cs_net_profit AS net_profit,
          cs.cs_order_number AS order_number,
          'catalog' AS channel
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          CAST(NULL AS integer),
          ss.ss_store_sk,
          ss.ss_item_sk,
          ss.ss_quantity,
          ss.ss_net_paid,
          ss.ss_net_profit,
          ss.ss_ticket_number,
          'store'
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          CAST(NULL AS integer),
          CAST(NULL AS integer),
          ws.ws_item_sk,
          ws.ws_quantity,
          ws.ws_net_paid,
          ws.ws_net_profit,
          ws.ws_order_number,
          'web'
   FROM web_sales ws
),
sales_with_returns AS (
   SELECT cs.*,
          CASE
              WHEN cs.channel = 'catalog' THEN COALESCE(cr.cr_return_quantity, 0)
              WHEN cs.channel = 'store' THEN COALESCE(sr.sr_return_quantity, 0)
              WHEN cs.channel = 'web' THEN COALESCE(wr.wr_return_quantity, 0)
              ELSE 0
          END AS return_qty,
          CASE
              WHEN cs.channel = 'catalog' THEN COALESCE(cr.cr_net_loss, 0)
              WHEN cs.channel = 'store' THEN COALESCE(sr.sr_net_loss, 0)
              WHEN cs.channel = 'web' THEN COALESCE(wr.wr_net_loss, 0)
              ELSE 0
          END AS net_loss
   FROM combined_sales cs
   LEFT JOIN catalog_returns cr
       ON cs.channel = 'catalog' AND cs.order_number = cr.cr_order_number
   LEFT JOIN store_returns sr
       ON cs.channel = 'store' AND cs.order_number = sr.sr_ticket_number
   LEFT JOIN web_returns wr
       ON cs.channel = 'web' AND cs.order_number = wr.wr_order_number
),
date_info AS (
   SELECT d.d_date_sk,
          d.d_date,
          d.d_year
   FROM date_dim d
   WHERE d.d_year BETWEEN 1998 AND 2000
),
sales_summary AS (
   SELECT
       s.date_sk,
       d.d_date,
       d.d_year,
       s.channel,
       COALESCE(s.cc_sk, 0) AS cc_sk,
       COALESCE(s.store_sk, 0) AS store_sk,
       SUM(s.quantity - s.return_qty) AS net_quantity,
       SUM(s.net_paid - s.net_loss) AS net_paid_adj,
       SUM(s.net_profit) AS total_profit,
       AVG(CASE WHEN s.net_paid > 0 THEN s.net_profit / s.net_paid ELSE NULL END) AS avg_profit_margin,
       COUNT(DISTINCT s.order_number) AS orders_count,
       MIN(s.order_number) AS min_order_number
   FROM sales_with_returns s
   LEFT JOIN date_info d ON s.date_sk = d.d_date_sk
   GROUP BY
       s.date_sk,
       d.d_date,
       d.d_year,
       s.channel,
       COALESCE(s.cc_sk, 0),
       COALESCE(s.store_sk, 0)
),
sales_ranked AS (
   SELECT
       ss.*,
       ROW_NUMBER() OVER (PARTITION BY ss.channel ORDER BY ss.total_profit DESC) AS profit_rank
   FROM sales_summary ss
),
final_result AS (
   SELECT
       a.d_year,
       a.channel,
       CASE
           WHEN a.channel = 'store' THEN CONCAT(st.s_store_name, ' - ', COALESCE(st.s_city, ''))
           WHEN a.channel = 'catalog' THEN CONCAT(cc.cc_name, ' - ', COALESCE(cc.cc_city, ''))
           ELSE 'Online'
       END AS entity_name,
       a.net_quantity,
       a.net_paid_adj,
       a.total_profit,
       a.avg_profit_margin,
       a.orders_count,
       a.profit_rank,
       CASE WHEN a.total_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category,
       COALESCE(CAST(a.total_profit / NULLIF(a.net_quantity, 0) AS DOUBLE), 0) AS profit_per_item,
       CASE
           WHEN a.channel = 'catalog' THEN (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_order_number = a.min_order_number)
           WHEN a.channel = 'store' THEN (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_ticket_number = a.min_order_number)
           WHEN a.channel = 'web' THEN (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_order_number = a.min_order_number)
           ELSE 0
       END AS specific_return_count
   FROM sales_ranked a
   LEFT JOIN store st ON a.store_sk = st.s_store_sk
   LEFT JOIN call_center cc ON a.cc_sk = cc.cc_call_center_sk
   WHERE a.profit_rank <= 5
)
SELECT *
FROM final_result
ORDER BY d_year DESC, channel, profit_rank
