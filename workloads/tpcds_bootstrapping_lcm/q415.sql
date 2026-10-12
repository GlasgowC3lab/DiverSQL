SELECT
    d.d_year,
    d.d_quarter_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_closed.d_date AS store_closed_date,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    (SUM(ss.ss_net_profit) - SUM(sr.sr_return_amt) - SUM(wr.wr_return_amt)) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_return_orders,
    AVG(ss.ss_quantity) AS avg_quantity_per_sale,
    MAX(ss.ss_sales_price) AS max_sales_price,
    MIN(ss.ss_sales_price) AS min_sales_price
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2020
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_closed.d_date
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
