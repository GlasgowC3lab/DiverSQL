SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_quarter_name,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_ticket_count,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_store_return_loss,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_store_return_quantity,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_web_return_quantity,
    (SUM(ss.ss_ext_sales_price) 
        - COALESCE(SUM(sr.sr_return_amt), 0) 
        - COALESCE(SUM(wr.wr_return_amt), 0)
    ) AS net_sales_amount,
    CASE WHEN d_closed.d_date_sk IS NOT NULL THEN 1 ELSE 0 END AS is_store_closed,
    CASE 
        WHEN SUM(ss.ss_ext_sales_price) > 0 
            THEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price) 
        ELSE NULL 
    END AS profit_margin
FROM store s
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_store_sk = s.s_store_sk
   AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN date_dim d_returns
    ON sr.sr_returned_date_sk = d_returns.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_returns.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_quarter_name,
    d_closed.d_date_sk
ORDER BY total_sales_amount DESC
LIMIT 100
