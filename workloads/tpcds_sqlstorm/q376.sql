WITH sales AS (
  SELECT ss.ss_sold_date_sk AS date_sk,
         ss.ss_store_sk AS store_sk,
         ss.ss_item_sk AS item_sk,
         ss.ss_quantity AS quantity,
         ss.ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT cs.cs_sold_date_sk,
         cs.cs_call_center_sk,
         cs.cs_item_sk,
         cs.cs_quantity,
         cs.cs_net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_web_page_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_net_profit,
         'web' AS channel
  FROM web_sales ws
),
returns AS (
  SELECT sr.sr_returned_date_sk AS date_sk,
         sr.sr_store_sk AS store_sk,
         sr.sr_item_sk AS item_sk,
         sr.sr_return_quantity AS quantity,
         sr.sr_net_loss AS net_loss,
         'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT cr.cr_returned_date_sk,
         cr.cr_call_center_sk,
         cr.cr_item_sk,
         cr.cr_return_quantity,
         cr.cr_net_loss,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_web_page_sk,
         wr.wr_item_sk,
         wr.wr_return_quantity,
         wr.wr_net_loss,
         'web' AS channel
  FROM web_returns wr
),
sales_agg AS (
  SELECT s.channel,
         d.d_year,
         d.d_month_seq AS month_seq,
         s.store_sk,
         SUM(s.quantity) AS total_quantity,
         SUM(s.net_profit) AS total_net_profit,
         SUM(s.net_profit) / NULLIF(SUM(s.quantity), 0) AS profit_per_quantity
  FROM sales s
  JOIN date_dim d ON s.date_sk = d.d_date_sk
  GROUP BY s.channel, d.d_year, d.d_month_seq, s.store_sk
),
returns_agg AS (
  SELECT r.channel,
         d.d_year,
         d.d_month_seq AS month_seq,
         r.store_sk,
         SUM(r.quantity) AS total_return_quantity,
         SUM(r.net_loss) AS total_returns_loss
  FROM returns r
  JOIN date_dim d ON r.date_sk = d.d_date_sk
  GROUP BY r.channel, d.d_year, d.d_month_seq, r.store_sk
),
combined AS (
  SELECT COALESCE(s.channel, r.channel) AS channel,
         COALESCE(s.d_year, r.d_year) AS d_year,
         COALESCE(s.month_seq, r.month_seq) AS month_seq,
         COALESCE(s.store_sk, r.store_sk) AS store_sk,
         COALESCE(s.total_quantity, 0) AS total_quantity,
         COALESCE(s.total_net_profit, 0) AS total_net_profit,
         COALESCE(s.profit_per_quantity, 0) AS profit_per_quantity,
         COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
         COALESCE(r.total_return_quantity, 0) AS total_return_quantity
  FROM sales_agg s
  FULL OUTER JOIN returns_agg r
    ON s.channel = r.channel
   AND s.d_year = r.d_year
   AND s.month_seq = r.month_seq
   AND s.store_sk = r.store_sk
),
ranked AS (
  SELECT c.*,
         ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY total_net_profit DESC) AS profit_rank
  FROM combined c
),
entity_names AS (
  SELECT s.s_store_sk AS store_sk, s.s_store_name AS store_name FROM store s
  UNION ALL
  SELECT cc.cc_call_center_sk AS store_sk, cc.cc_name AS store_name FROM call_center cc
  UNION ALL
  SELECT wp.wp_web_page_sk AS store_sk, wp.wp_url AS store_name FROM web_page wp
)
SELECT r.channel,
       r.d_year,
       r.month_seq,
       r.store_sk,
       e.store_name,
       r.total_quantity,
       r.total_net_profit,
       r.profit_per_quantity,
       r.total_returns_loss,
       r.total_return_quantity,
       r.profit_rank
FROM ranked r
JOIN entity_names e ON r.store_sk = e.store_sk
WHERE r.profit_rank <= 10
ORDER BY r.channel, r.d_year, r.profit_rank
