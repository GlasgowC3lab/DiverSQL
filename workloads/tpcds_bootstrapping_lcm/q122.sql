SELECT
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_seq,
    cp.cp_type,
    cp.cp_department,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_quantity) AS total_quantity,
    sum(ss.ss_net_profit) AS total_profit,
    sum(ss.ss_ext_discount_amt) AS total_discount,
    sum(wr.wr_return_amt) AS total_return_amount,
    sum(wr.wr_return_quantity) AS total_return_quantity,
    sum(ss.ss_ext_sales_price) - coalesce(sum(wr.wr_return_amt), 0) AS net_sales,
    CASE
        WHEN sum(ss.ss_ext_sales_price) = 0 THEN NULL
        ELSE sum(ss.ss_ext_discount_amt) / sum(ss.ss_ext_sales_price)
    END AS discount_rate,
    sum(ss.ss_net_profit) - coalesce(sum(wr.wr_net_loss), 0) AS net_profit_after_returns,
    date_diff('day', MIN(d_cp_end.d_date), MIN(d_sold.d_date)) AS days_between_page_end_and_sale,
    date_diff('day', MIN(d_closed.d_date), MIN(d_sold.d_date)) AS days_since_store_closed
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY ROLLUP (s.s_state, d_sold.d_year, d_sold.d_quarter_seq, cp.cp_type, cp.cp_department)
