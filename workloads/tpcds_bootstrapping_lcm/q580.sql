SELECT 
    cc.cc_market_manager,
    cc.cc_city,
    s.s_state,
    s.s_city,
    d_return.d_year,
    d_return.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_net_loss) AS total_net_loss,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_fee), 0), 2) AS return_to_fee_ratio,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    MIN(date_diff('day', d_cc_open.d_date, d_return.d_date)) AS min_days_since_open,
    MAX(date_diff('day', d_cc_open.d_date, d_return.d_date)) AS max_days_since_open,
    CASE 
        WHEN SUM(cr.cr_return_amount) > 10000 THEN 'High'
        WHEN SUM(cr.cr_return_amount) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category
FROM call_center cc
JOIN catalog_returns cr 
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_return 
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_cc_open 
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s 
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE cc.cc_market_manager IS NOT NULL
GROUP BY 
    cc.cc_market_manager,
    cc.cc_city,
    s.s_state,
    s.s_city,
    d_return.d_year,
    d_return.d_month_seq
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
