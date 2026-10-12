SELECT
    cc.cc_company_name,
    s.s_store_name,
    d_cc_closed.d_year AS sales_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_fee) AS total_return_fee,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
FROM date_dim d_cc_closed
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cc_closed.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE d_cc_closed.d_year = 2001
GROUP BY cc.cc_company_name, s.s_store_name, d_cc_closed.d_year
ORDER BY total_net_profit DESC
LIMIT 100
