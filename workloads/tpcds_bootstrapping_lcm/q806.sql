SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    s.s_floor_space,
    s.s_gmt_offset,
    date_diff('day', d_sold.d_date, d_closure.d_date) AS days_until_store_closed,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_fee, 0)) AS total_return_fee,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) > 0
        THEN SUM(COALESCE(wr.wr_return_amt, 0)) / SUM(ss.ss_ext_sales_price)
        ELSE NULL
    END AS return_to_sales_ratio
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_day_name,
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    s.s_floor_space,
    s.s_gmt_offset,
    d_sold.d_date,
    d_closure.d_date
HAVING SUM(ss.ss_ext_sales_price) > 0
ORDER BY total_net_profit DESC
LIMIT 100
