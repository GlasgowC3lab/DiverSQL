SELECT
    s.s_store_name,
    cc.cc_name AS call_center_name,
    d_sales.d_year,
    d_sales.d_moy AS month,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax_pct,
    CASE
        WHEN SUM(ss.ss_quantity) > 0 THEN
            (COALESCE(SUM(cr.cr_return_quantity), 0) / SUM(ss.ss_quantity)) * 100
        ELSE NULL
    END AS return_quantity_pct
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
LEFT JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_sales.d_year = 2020
  AND (d_cc_open.d_date IS NULL OR d_cc_open.d_date <= d_sales.d_date)
  AND (d_cc_closed.d_date IS NULL OR d_cc_closed.d_date > d_sales.d_date)
  AND (d_store_closed.d_date IS NULL OR d_store_closed.d_date > d_sales.d_date)
GROUP BY
    s.s_store_name,
    cc.cc_name,
    d_sales.d_year,
    d_sales.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 100
