SELECT
    cc.cc_call_center_id,
    s.s_store_id,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax_percentage,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    (SUM(ss.ss_ext_sales_price) - SUM(cr.cr_return_amount)) AS net_sales_after_returns,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
        ELSE SUM(cr.cr_return_amount) / SUM(ss.ss_ext_sales_price)
    END AS return_to_sales_ratio
FROM date_dim d_sales
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
LEFT JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sales.d_year >= 2000
GROUP BY
    cc.cc_call_center_id,
    s.s_store_id,
    d_sales.d_year,
    d_sales.d_month_seq
ORDER BY total_sales_amount DESC
LIMIT 100
