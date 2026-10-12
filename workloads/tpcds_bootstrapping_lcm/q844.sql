SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    d.d_current_month,
    COALESCE(r.r_reason_desc, 'No Return') AS return_reason,
    d_closed.d_year AS store_closed_year,
    d_closed.d_current_day AS store_closed_day,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT wr.wr_order_number) AS return_transactions,
    ROUND(
        CASE
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL
            ELSE SUM(COALESCE(wr.wr_return_amt, 0)) / SUM(ss.ss_ext_sales_price)
        END,
        4
    ) AS return_to_sales_ratio
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    d.d_current_month,
    COALESCE(r.r_reason_desc, 'No Return'),
    d_closed.d_year,
    d_closed.d_current_day
HAVING SUM(ss.ss_ext_sales_price) > 50000
ORDER BY total_sales_amount DESC
LIMIT 20
