SELECT
    cc.cc_market_manager,
    ws.web_market_manager,
    s.s_division_name,
    d_sale.d_year,
    d_sale.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(*) AS total_transactions
FROM store_sales ss
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sale.d_date_sk
WHERE d_sale.d_year BETWEEN 2000 AND 2005
  AND s.s_state = 'CA'
  AND cc.cc_tax_percentage > 0
GROUP BY
    cc.cc_market_manager,
    ws.web_market_manager,
    s.s_division_name,
    d_sale.d_year,
    d_sale.d_month_seq
HAVING SUM(ss.ss_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
