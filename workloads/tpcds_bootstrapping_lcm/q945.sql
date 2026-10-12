SELECT
    d_sale.d_year,
    d_sale.d_month_seq,
    s.s_state,
    s.s_city,
    s.s_store_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_items_sold,
    COALESCE(SUM(ws.wr_return_quantity), 0) AS total_return_quantity,
    COALESCE(SUM(ws.wr_return_amt), 0) AS total_return_amount,
    SUM(ss.ss_net_profit) AS total_net_profit_sales,
    COALESCE(SUM(ws.wr_net_loss), 0) AS total_net_loss_returns,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(ws.wr_net_loss), 0)) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets_sold,
    COUNT(DISTINCT ws.wr_order_number) AS distinct_return_orders,
    MAX(r.r_reason_desc) AS most_common_return_reason
FROM store_sales ss
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim cd
    ON s.s_closed_date_sk = cd.d_date_sk
LEFT JOIN web_returns ws
    ON ws.wr_returned_date_sk = d_sale.d_date_sk
LEFT JOIN reason r
    ON ws.wr_reason_sk = r.r_reason_sk
WHERE d_sale.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    d_sale.d_year,
    d_sale.d_month_seq,
    s.s_state,
    s.s_city,
    s.s_store_name
ORDER BY net_profit_after_returns DESC
LIMIT 100
