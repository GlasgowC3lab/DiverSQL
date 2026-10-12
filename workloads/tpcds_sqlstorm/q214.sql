WITH
sales_base AS (
   SELECT
     'store' AS channel,
     ss.ss_sold_date_sk AS date_sk,
     d.d_year,
     d.d_month_seq,
     ss.ss_item_sk AS item_sk,
     ss.ss_store_sk AS store_sk,
     ss.ss_quantity AS quantity,
     ss.ss_net_paid AS net_paid,
     ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
     ss.ss_net_profit AS net_profit,
     ss.ss_ticket_number AS ticket_number,
     s.s_store_name AS store_name,
     i.i_product_name AS i_product_name,
     i.i_category AS i_category,
     i.i_brand AS i_brand,
     i.i_color AS i_color
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
   UNION ALL
   SELECT
     'catalog' AS channel,
     cs.cs_sold_date_sk AS date_sk,
     d.d_year,
     d.d_month_seq,
     cs.cs_item_sk AS item_sk,
     cs.cs_call_center_sk AS store_sk,
     cs.cs_quantity AS quantity,
     cs.cs_net_paid AS net_paid,
     cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
     cs.cs_net_profit AS net_profit,
     cs.cs_order_number AS ticket_number,
     cc.cc_name AS store_name,
     i.i_product_name AS i_product_name,
     i.i_category AS i_category,
     i.i_brand AS i_brand,
     i.i_color AS i_color
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
   UNION ALL
   SELECT
     'web' AS channel,
     ws.ws_sold_date_sk AS date_sk,
     d.d_year,
     d.d_month_seq,
     ws.ws_item_sk AS item_sk,
     ws.ws_web_page_sk AS store_sk,
     ws.ws_quantity AS quantity,
     ws.ws_net_paid AS net_paid,
     ws.ws_net_paid_inc_tax AS net_paid_inc_tax,
     ws.ws_net_profit AS net_profit,
     ws.ws_order_number AS ticket_number,
     wp.wp_url AS store_name,
     i.i_product_name AS i_product_name,
     i.i_category AS i_category,
     i.i_brand AS i_brand,
     i.i_color AS i_color
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
),
returns_base AS (
   SELECT
     'store' AS channel,
     sr.sr_returned_date_sk AS date_sk,
     d.d_year,
     d.d_month_seq,
     sr.sr_item_sk AS item_sk,
     sr.sr_store_sk AS store_sk,
     sr.sr_return_quantity AS return_quantity,
     sr.sr_return_amt AS return_amount,
     sr.sr_net_loss AS net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
   UNION ALL
   SELECT
     'catalog' AS channel,
     cr.cr_returned_date_sk AS date_sk,
     d.d_year,
     d.d_month_seq,
     cr.cr_item_sk AS item_sk,
     cr.cr_call_center_sk AS store_sk,
     cr.cr_return_quantity AS return_quantity,
     cr.cr_return_amount AS return_amount,
     cr.cr_net_loss AS net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
   UNION ALL
   SELECT
     'web' AS channel,
     wr.wr_returned_date_sk AS date_sk,
     d.d_year,
     d.d_month_seq,
     wr.wr_item_sk AS item_sk,
     wr.wr_web_page_sk AS store_sk,
     wr.wr_return_quantity AS return_quantity,
     wr.wr_return_amt AS return_amount,
     wr.wr_net_loss AS net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2000
),
sales_with_returns AS (
   SELECT
     s.channel,
     s.date_sk,
     s.d_year,
     s.d_month_seq,
     s.item_sk,
     s.store_sk,
     s.quantity,
     s.net_paid,
     s.net_paid_inc_tax,
     s.net_profit,
     COALESCE(r.return_quantity, 0) AS return_quantity,
     COALESCE(r.return_amount, 0) AS return_amount,
     COALESCE(r.net_loss, 0) AS net_loss,
     s.net_profit - COALESCE(r.net_loss, 0) AS adj_net_profit,
     CASE
       WHEN (s.net_paid - COALESCE(r.return_amount, 0)) = 0 THEN 0
       ELSE (s.net_profit - COALESCE(r.net_loss, 0)) / (s.net_paid - COALESCE(r.return_amount, 0))
     END AS profit_margin,
     s.store_name,
     s.i_product_name,
     s.i_category,
     s.i_brand,
     s.i_color
   FROM sales_base s
   LEFT JOIN returns_base r
     ON s.channel = r.channel
    AND s.item_sk = r.item_sk
    AND s.store_sk = r.store_sk
    AND s.d_month_seq = r.d_month_seq
),
agg_month_item_raw AS (
   SELECT
     channel,
     d_year,
     d_month_seq,
     item_sk,
     i_product_name,
     i_category,
     i_brand,
     i_color,
     SUM(quantity) AS total_quantity,
     SUM(return_quantity) AS total_returns,
     SUM(net_paid) AS total_net_paid,
     SUM(return_amount) AS total_return_amount,
     SUM(adj_net_profit) AS total_adj_net_profit,
     CASE
        WHEN SUM(quantity) = 0 THEN 'None'
        WHEN SUM(adj_net_profit) / NULLIF(SUM(quantity),0) > 100 THEN 'High'
        WHEN SUM(adj_net_profit) / NULLIF(SUM(quantity),0) > 20 THEN 'Medium'
        ELSE 'Low'
     END AS profit_bracket,
     CONCAT(i_product_name, ' - ', i_brand) AS product_display
   FROM sales_with_returns
   GROUP BY
     channel,
     d_year,
     d_month_seq,
     item_sk,
     i_product_name,
     i_category,
     i_brand,
     i_color
),
agg_month_item AS (
   SELECT
     r.*,
     ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY total_adj_net_profit DESC) AS profit_rank,
     SUM(total_adj_net_profit) OVER (PARTITION BY channel ORDER BY d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_adj_profit
   FROM agg_month_item_raw r
),
store_not_in_web AS (
   SELECT DISTINCT
     s.channel,
     s.d_year,
     s.d_month_seq,
     s.item_sk,
     s.i_product_name
   FROM agg_month_item s
   WHERE s.channel = 'store'
     AND NOT EXISTS (
         SELECT 1
         FROM agg_month_item w
         WHERE w.channel = 'web'
           AND w.item_sk = s.item_sk
           AND w.d_month_seq = s.d_month_seq
           AND w.d_year = s.d_year
     )
)
SELECT
  a.channel,
  a.d_year,
  CAST(a.d_month_seq AS VARCHAR) || '-2020' AS month_label,
  a.product_display,
  a.i_category,
  a.i_brand,
  a.i_color,
  a.total_quantity,
  a.total_returns,
  round(a.total_adj_net_profit, 2) AS total_adj_net_profit,
  a.profit_bracket,
  a.profit_rank,
  round(a.cumulative_adj_profit, 2) AS cumulative_adj_profit,
  CASE WHEN snw.item_sk IS NOT NULL THEN 'StoreOnly' ELSE '' END AS exclusivity_flag,
  (SELECT round(prev.cumulative_adj_profit, 2)
   FROM agg_month_item prev
   WHERE prev.channel = a.channel
     AND prev.item_sk = a.item_sk
     AND prev.d_month_seq = a.d_month_seq - 1) AS prev_month_cum_profit,
  reverse(upper(a.product_display)) AS reversed_display,
  COALESCE(a.i_color, 'UNKNOWN') AS color_coalesced
FROM agg_month_item a
LEFT JOIN store_not_in_web snw
  ON a.channel = snw.channel
 AND a.item_sk = snw.item_sk
 AND a.d_month_seq = snw.d_month_seq
 AND a.d_year = snw.d_year
WHERE a.profit_rank <= 10
ORDER BY a.d_year, a.d_month_seq, a.channel, a.profit_rank
