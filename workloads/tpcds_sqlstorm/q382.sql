WITH
sales_unified AS (
 SELECT
   ss.ss_sold_date_sk AS date_sk,
   d.d_date AS sold_date,
   i.i_item_sk,
   i.i_item_id,
   i.i_product_name,
   i.i_category,
   i.i_class,
   ss.ss_customer_sk AS customer_sk,
   ss.ss_store_sk AS location_sk,
   'store' AS channel,
   ss.ss_quantity AS quantity,
   (ss.ss_net_profit - COALESCE(p.p_cost, 0) - COALESCE(sr.sr_net_loss, 0)) AS net_profit_adj,
   COALESCE(sr.sr_net_loss, 0) AS return_loss
 FROM store_sales ss
 LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
 LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
 LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
 WHERE ss.ss_quantity > 0
 UNION ALL
 SELECT
   cs.cs_sold_date_sk AS date_sk,
   d.d_date AS sold_date,
   i.i_item_sk,
   i.i_item_id,
   i.i_product_name,
   i.i_category,
   i.i_class,
   cs.cs_bill_customer_sk AS customer_sk,
   cs.cs_call_center_sk AS location_sk,
   'catalog' AS channel,
   cs.cs_quantity AS quantity,
   (cs.cs_net_profit - COALESCE(p.p_cost, 0) - COALESCE(cr.cr_net_loss, 0)) AS net_profit_adj,
   COALESCE(cr.cr_net_loss, 0) AS return_loss
 FROM catalog_sales cs
 LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
 LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
 LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
 WHERE cs.cs_quantity > 0
 UNION ALL
 SELECT
   ws.ws_sold_date_sk AS date_sk,
   d.d_date AS sold_date,
   i.i_item_sk,
   i.i_item_id,
   i.i_product_name,
   i.i_category,
   i.i_class,
   ws.ws_bill_customer_sk AS customer_sk,
   ws.ws_web_page_sk AS location_sk,
   'web' AS channel,
   ws.ws_quantity AS quantity,
   (ws.ws_net_profit - COALESCE(p.p_cost, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_profit_adj,
   COALESCE(wr.wr_net_loss, 0) AS return_loss
 FROM web_sales ws
 LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
 LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
 LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
 WHERE ws.ws_quantity > 0
),
item_monthly_stats AS (
 SELECT
   i_item_sk,
   CAST(date_trunc('month', CAST(sold_date AS timestamp)) AS date) AS month,
   sum(net_profit_adj) AS total_net_profit,
   sum(quantity) AS total_quantity,
   avg(net_profit_adj) AS avg_net_profit,
   rank() OVER (ORDER BY sum(net_profit_adj) DESC) AS profit_rank_month
 FROM sales_unified
 GROUP BY i_item_sk, CAST(date_trunc('month', CAST(sold_date AS timestamp)) AS date)
),
item_monthly_trend AS (
 SELECT
   ims.i_item_sk,
   ims.month,
   ims.total_net_profit,
   ims.total_quantity,
   ims.avg_net_profit,
   ims.profit_rank_month,
   sum(ims.total_net_profit) OVER (PARTITION BY ims.i_item_sk ORDER BY ims.month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_3month_profit,
   CASE
     WHEN sum(ims.total_net_profit) OVER (PARTITION BY ims.i_item_sk ORDER BY ims.month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) < 0 THEN 'LOSS' ELSE 'PROFIT'
   END AS profit_trend
 FROM item_monthly_stats ims
),
item_total_agg AS (
 SELECT
   i_item_sk,
   sum(quantity) AS total_quantity,
   avg(net_profit_adj) AS avg_net_profit,
   sum(return_loss) AS total_return_loss
 FROM sales_unified
 GROUP BY i_item_sk
)
SELECT
  CAST(imt.i_item_sk AS varchar) AS entity_id,
  i.i_product_name AS entity_name,
  imt.month AS period,
  imt.total_net_profit,
  imt.moving_3month_profit,
  imt.profit_trend,
  imt.profit_rank_month,
  ia.total_quantity,
  ia.avg_net_profit,
  ia.total_return_loss AS return_loss,
  CASE
    WHEN imt.total_net_profit > 0 THEN 'POSITIVE'
    WHEN imt.total_net_profit < 0 THEN 'NEGATIVE'
    ELSE 'ZERO'
  END AS profit_sign,
  imt.total_net_profit / nullif(ia.total_quantity, 0) AS profit_per_quantity,
  CONCAT('Item ', COALESCE(i.i_item_id, 'UNK'), ' (', COALESCE(i.i_category, 'NC'), ') month ', format_datetime(CAST(imt.month AS timestamp), '%Y-%m'), ': ', imt.profit_trend) AS summary_msg,
  (SELECT avg(ms2.total_net_profit)
   FROM item_monthly_stats ms2
   JOIN item i2 ON ms2.i_item_sk = i2.i_item_sk
   WHERE i2.i_category = i.i_category) AS category_avg_profit
FROM item_monthly_trend imt
JOIN item i ON imt.i_item_sk = i.i_item_sk
LEFT JOIN item_total_agg ia ON ia.i_item_sk = imt.i_item_sk
WHERE (imt.profit_trend = 'LOSS' AND ia.total_return_loss > 5000)
   OR (imt.profit_trend = 'PROFIT' AND imt.moving_3month_profit > 20000)

UNION ALL

SELECT
  CAST(s.customer_sk AS varchar) AS entity_id,
  concat(c.c_first_name, ' ', c.c_last_name) AS entity_name,
  NULL AS period,
  sum(s.net_profit_adj) AS total_net_profit,
  NULL AS moving_3month_profit,
  NULL AS profit_trend,
  NULL AS ranking,
  sum(s.quantity) AS total_quantity,
  NULL AS avg_net_profit,
  sum(s.return_loss) AS return_loss,
  CASE WHEN sum(s.net_profit_adj) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_sign,
  sum(s.net_profit_adj) / nullif(sum(s.quantity), 0) AS profit_per_quantity,
  CONCAT('Customer ', c.c_customer_id, ' total net profit: ', CAST(sum(s.net_profit_adj) AS varchar)) AS summary_msg,
  NULL AS category_avg_profit
FROM sales_unified s
JOIN customer c ON s.customer_sk = c.c_customer_sk
GROUP BY s.customer_sk, c.c_first_name, c.c_last_name, c.c_customer_id
HAVING sum(s.net_profit_adj) > 10000
ORDER BY entity_id
