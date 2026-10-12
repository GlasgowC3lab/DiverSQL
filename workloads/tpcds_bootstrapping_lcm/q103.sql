SELECT
  ca.ca_state,
  d_sales.d_year,
  d_sales.d_month_seq,
  s.s_store_name,
  SUM(ss.ss_ext_sales_price) AS total_sales_amount,
  SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
  SUM(ss.ss_net_profit) AS total_net_profit,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_net_loss) AS total_return_loss,
  SUM(ss.ss_ext_sales_price) - SUM(wr.wr_return_amt) AS net_sales_after_returns,
  (SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0)) AS profit_margin,
  COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
  COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
  AVG(ss.ss_quantity) AS avg_quantity_per_sale,
  AVG(wr.wr_return_quantity) AS avg_quantity_per_return
FROM store_sales ss
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN web_returns wr
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sales.d_year = 2022
  AND d_return.d_year = 2022
  AND d_store_closed.d_year = 2022
GROUP BY ca.ca_state, d_sales.d_year, d_sales.d_month_seq, s.s_store_name
HAVING SUM(ss.ss_ext_sales_price) > 50000
ORDER BY total_sales_amount DESC
LIMIT 100
