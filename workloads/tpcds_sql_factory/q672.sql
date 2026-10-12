WITH sales_by_store_month AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    i.i_category,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    i.i_category
)
SELECT
  s_store_id,
  s_store_name,
  d_year,
  d_current_month,
  i_category,
  total_profit,
  total_quantity,
  num_orders,
  CASE
    WHEN total_profit > 100000 THEN 'HIGH'
    WHEN total_profit > 50000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  RANK() OVER (PARTITION BY s_store_id, i_category ORDER BY total_profit DESC) AS profit_month_rank
FROM sales_by_store_month
ORDER BY s_store_id, i_category, profit_month_rank
LIMIT 100
