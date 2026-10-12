WITH
sales AS (
  SELECT d.d_year,
         d.d_quarter_name,
         i.i_category,
         'Store' AS channel,
         SUM(ss.ss_net_paid_inc_tax) AS total_sales,
         SUM(ss.ss_net_profit) AS total_profit,
         COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
         AVG(ss.ss_ext_discount_amt) AS avg_discount,
         SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_quarter_name, i.i_category
  UNION ALL
  SELECT d.d_year,
         d.d_quarter_name,
         i.i_category,
         'Catalog' AS channel,
         SUM(cs.cs_net_paid_inc_tax) AS total_sales,
         SUM(cs.cs_net_profit) AS total_profit,
         COUNT(DISTINCT cs.cs_order_number) AS order_count,
         AVG(cs.cs_ext_discount_amt) AS avg_discount,
         SUM(cs.cs_quantity) AS total_quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_quarter_name, i.i_category
  UNION ALL
  SELECT d.d_year,
         d.d_quarter_name,
         i.i_category,
         'Web' AS channel,
         SUM(ws.ws_net_paid_inc_tax) AS total_sales,
         SUM(ws.ws_net_profit) AS total_profit,
         COUNT(DISTINCT ws.ws_order_number) AS order_count,
         AVG(ws.ws_ext_discount_amt) AS avg_discount,
         SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_quarter_name, i.i_category
),
returns AS (
  SELECT d.d_year,
         d.d_quarter_name,
         i.i_category,
         'Store' AS channel,
         SUM(sr.sr_net_loss) AS total_return_loss,
         SUM(sr.sr_return_quantity) AS return_quantity,
         COUNT(DISTINCT sr.sr_ticket_number) AS return_orders
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_quarter_name, i.i_category
  UNION ALL
  SELECT d.d_year,
         d.d_quarter_name,
         i.i_category,
         'Catalog' AS channel,
         SUM(cr.cr_net_loss) AS total_return_loss,
         SUM(cr.cr_return_quantity) AS return_quantity,
         COUNT(DISTINCT cr.cr_order_number) AS return_orders
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_quarter_name, i.i_category
  UNION ALL
  SELECT d.d_year,
         d.d_quarter_name,
         i.i_category,
         'Web' AS channel,
         SUM(wr.wr_net_loss) AS total_return_loss,
         SUM(wr.wr_return_quantity) AS return_quantity,
         COUNT(DISTINCT wr.wr_order_number) AS return_orders
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_quarter_name, i.i_category
),
combined AS (
  SELECT s.d_year,
         s.d_quarter_name,
         s.i_category,
         s.channel,
         s.total_sales,
         s.total_profit,
         s.order_count,
         s.avg_discount,
         s.total_quantity,
         COALESCE(r.total_return_loss, 0) AS total_return_loss,
         COALESCE(r.return_quantity, 0) AS return_quantity,
         COALESCE(r.return_orders, 0) AS return_orders
  FROM sales s
  LEFT JOIN returns r
    ON s.d_year = r.d_year
   AND s.d_quarter_name = r.d_quarter_name
   AND s.i_category = r.i_category
   AND s.channel = r.channel
)
SELECT
  d_year,
  d_quarter_name,
  i_category,
  channel,
  total_sales,
  total_profit,
  total_return_loss,
  (total_sales - total_return_loss) AS net_sales_after_returns,
  total_quantity,
  return_quantity,
  (total_sales - total_return_loss) / NULLIF(total_quantity, 0) AS avg_sales_per_item,
  CASE WHEN total_sales > 0 THEN (total_profit / total_sales) * 100 ELSE NULL END AS profit_margin_pct,
  order_count,
  avg_discount,
  return_orders,
  sales_rank
FROM (
  SELECT
    d_year,
    d_quarter_name,
    i_category,
    channel,
    total_sales,
    total_profit,
    total_return_loss,
    total_quantity,
    return_quantity,
    order_count,
    avg_discount,
    return_orders,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS sales_rank
  FROM combined
) t
WHERE sales_rank <= 10
ORDER BY channel, sales_rank
