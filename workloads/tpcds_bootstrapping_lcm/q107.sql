SELECT
    s.s_store_id,
    s.s_store_name,
    cc.cc_name,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(wr.wr_net_loss) AS total_return_loss,
    SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_sales,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE ROUND(100.0 * SUM(wr.wr_net_loss) / SUM(ss.ss_ext_sales_price), 2)
    END AS return_loss_percentage,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
  AND s.s_state = 'CA'
  AND cc.cc_market_manager IS NOT NULL
GROUP BY ROLLUP (s.s_store_id, s.s_store_name, cc.cc_name, d.d_year, d.d_month_seq)
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY net_sales DESC
LIMIT 100
