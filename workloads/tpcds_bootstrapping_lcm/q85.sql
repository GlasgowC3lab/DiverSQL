WITH aggregated AS (
  SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    s.s_store_id,
    s.s_city,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    (SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt)) AS net_revenue,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_days,
    AVG(date_diff('day', d_sold.d_date, d_return.d_date)) AS avg_return_days
  FROM web_sales ws
  JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
  GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    s.s_store_id,
    s.s_city,
    s.s_state
)
SELECT
  a.d_year,
  a.d_month_seq,
  a.d_current_month,
  a.s_store_id,
  a.s_city,
  a.s_state,
  a.total_orders,
  a.total_sales,
  a.total_discount,
  a.total_net_paid,
  a.total_return_amount,
  a.total_return_loss,
  a.net_revenue,
  a.avg_ship_days,
  a.avg_return_days,
  ROW_NUMBER() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.net_revenue DESC) AS revenue_rank
FROM aggregated a
ORDER BY a.net_revenue DESC
LIMIT 100
