SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    r.r_reason_desc,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(wr.wr_return_amt) AS total_return_amount,
    CASE WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
         ELSE SUM(ss.ss_ext_sales_price) / SUM(wr.wr_return_amt)
    END AS sales_to_return_ratio,
    CAST(SUM(wr.wr_return_quantity) AS double) / NULLIF(SUM(ss.ss_quantity), 0) AS return_quantity_ratio,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    AVG(
        CASE 
            WHEN d_closed.d_date IS NOT NULL 
            THEN date_diff('day', d_sold.d_date, d_closed.d_date) 
            ELSE NULL 
        END
    ) AS avg_days_to_store_closure,
    SUM(CASE WHEN wr.wr_return_quantity > ss.ss_quantity THEN 1 ELSE 0 END) AS return_qty_exceeds_sales_qty
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    r.r_reason_desc
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100
