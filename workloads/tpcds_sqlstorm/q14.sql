WITH sales AS (
 SELECT
  'store' AS channel,
  ss.ss_sold_date_sk AS date_sk,
  ss.ss_item_sk AS item_sk,
  ss.ss_customer_sk AS customer_sk,
  ss.ss_quantity AS quantity,
  ss.ss_net_paid_inc_tax AS net_sales,
  ss.ss_net_profit AS net_profit,
  ss.ss_ticket_number AS ticket_number
 FROM store_sales ss
 UNION ALL
 SELECT
  'catalog' AS channel,
  cs.cs_sold_date_sk,
  cs.cs_item_sk,
  cs.cs_bill_customer_sk,
  cs.cs_quantity,
  cs.cs_net_paid_inc_tax,
  cs.cs_net_profit,
  cs.cs_order_number
 FROM catalog_sales cs
 UNION ALL
 SELECT
  'web' AS channel,
  ws.ws_sold_date_sk,
  ws.ws_item_sk,
  ws.ws_bill_customer_sk,
  ws.ws_quantity,
  ws.ws_net_paid_inc_tax,
  ws.ws_net_profit,
  ws.ws_order_number
 FROM web_sales ws
), returns AS (
 SELECT
  'store' AS channel,
  sr.sr_item_sk AS item_sk,
  sr.sr_customer_sk AS customer_sk,
  sr.sr_ticket_number AS ticket_number,
  sr.sr_return_quantity AS quantity,
  sr.sr_return_amt_inc_tax AS net_return
 FROM store_returns sr
 UNION ALL
 SELECT
  'catalog' AS channel,
  cr.cr_item_sk,
  cr.cr_refunded_customer_sk,
  cr.cr_order_number,
  cr.cr_return_quantity,
  cr.cr_return_amt_inc_tax
 FROM catalog_returns cr
 UNION ALL
 SELECT
  'web' AS channel,
  wr.wr_item_sk,
  wr.wr_refunded_customer_sk,
  wr.wr_order_number,
  wr.wr_return_quantity,
  wr.wr_return_amt_inc_tax
 FROM web_returns wr
), returns_agg AS (
 SELECT
  channel,
  item_sk,
  customer_sk,
  ticket_number,
  SUM(quantity) AS returned_quantity,
  SUM(net_return) AS returned_amount
 FROM returns
 GROUP BY channel, item_sk, customer_sk, ticket_number
), sales_with_dim AS (
 SELECT
  s.channel,
  d.d_year,
  d.d_quarter_seq,
  i.i_category,
  s.item_sk,
  s.customer_sk,
  s.quantity,
  s.net_sales,
  s.net_profit,
  s.ticket_number
 FROM sales s
 JOIN date_dim d ON s.date_sk = d.d_date_sk
 JOIN item i ON s.item_sk = i.i_item_sk
), combined AS (
 SELECT
  s.channel,
  s.d_year,
  s.d_quarter_seq,
  s.i_category,
  s.item_sk,
  s.customer_sk,
  s.quantity AS sold_quantity,
  s.net_sales,
  s.net_profit,
  COALESCE(r.returned_quantity, 0) AS returned_quantity,
  COALESCE(r.returned_amount, 0) AS returned_amount
 FROM sales_with_dim s
 LEFT JOIN returns_agg r
   ON s.channel = r.channel
  AND s.item_sk = r.item_sk
  AND s.customer_sk = r.customer_sk
  AND s.ticket_number = r.ticket_number
), aggregated AS (
 SELECT
  channel,
  d_year,
  d_quarter_seq,
  i_category,
  SUM(net_sales) AS total_sales_amount,
  SUM(returned_amount) AS total_return_amount,
  SUM(net_sales) - SUM(returned_amount) AS net_sales_amount,
  SUM(net_profit) AS total_sales_profit,
  SUM(sold_quantity) AS total_quantity_sold,
  SUM(returned_quantity) AS total_quantity_returned,
  COUNT(DISTINCT customer_sk) AS distinct_customers,
  approx_percentile(net_profit, 0.95) AS p95_sales_profit
 FROM combined
 GROUP BY channel, d_year, d_quarter_seq, i_category
), ranked AS (
 SELECT
  *,
  RANK() OVER (PARTITION BY channel ORDER BY net_sales_amount DESC) AS category_sales_rank,
  LAG(net_sales_amount) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_quarter_seq) AS prev_net_sales_amount
 FROM aggregated
)
SELECT
  channel,
  d_year,
  d_quarter_seq,
  i_category,
  total_sales_amount,
  total_return_amount,
  net_sales_amount,
  total_sales_profit,
  total_quantity_sold,
  total_quantity_returned,
  distinct_customers,
  p95_sales_profit,
  category_sales_rank,
  CASE WHEN prev_net_sales_amount IS NULL THEN NULL
       ELSE (net_sales_amount - prev_net_sales_amount) / NULLIF(prev_net_sales_amount, 0)
  END AS qtr_growth_ratio
FROM ranked
ORDER BY channel, d_year, d_quarter_seq, category_sales_rank
LIMIT 100
