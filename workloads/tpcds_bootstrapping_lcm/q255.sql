SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_name AS call_center_name,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date,
    d_store_closed.d_date AS store_closed_date,
    d_sales.d_date AS transaction_date,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(cr.cr_order_number) AS total_returns,
    AVG(ss.ss_quantity) AS avg_quantity_sold,
    MAX(ss.ss_sales_price) AS max_sales_price,
    cc.cc_tax_percentage,
    s.s_tax_percentage
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_name,
    d_cc_open.d_date,
    d_cc_closed.d_date,
    d_store_closed.d_date,
    d_sales.d_date,
    cc.cc_tax_percentage,
    s.s_tax_percentage
ORDER BY total_store_net_profit DESC
LIMIT 100
