SELECT
    d.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return_amount,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return_amount,
    SUM(ss.ss_net_paid) - COALESCE(SUM(sr.sr_return_amt), 0) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_revenue,
    CASE WHEN SUM(ss.ss_net_paid) > 0 THEN
        (COALESCE(SUM(sr.sr_return_amt), 0) + COALESCE(SUM(wr.wr_return_amt), 0)) / SUM(ss.ss_net_paid)
    ELSE 0 END AS total_return_rate,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    MAX(ss.ss_sales_price) AS max_sales_price,
    MIN(ss.ss_sales_price) AS min_sales_price,
    DATE_DIFF('day', d.d_date, MAX(d_closed.d_date)) AS days_since_store_closed
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_date, s.s_store_id, s.s_store_name, s.s_state
HAVING SUM(ss.ss_net_paid) > 1000
ORDER BY net_revenue DESC
LIMIT 100
