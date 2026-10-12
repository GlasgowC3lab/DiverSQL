SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month,
    d_store_closed.d_year AS store_closed_year,
    d_return.d_year AS return_year,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    COUNT(DISTINCT wr.wr_order_number) AS return_transactions,
    AVG(CASE WHEN cd_sales.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customer_ratio,
    AVG(CASE WHEN cd_returns.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_return_ratio,
    COUNT(DISTINCT cd_returns_returning.cd_demo_sk) AS distinct_returning_customers
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_demographics cd_sales
    ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN customer_demographics cd_returns
    ON wr.wr_refunded_cdemo_sk = cd_returns.cd_demo_sk
LEFT JOIN customer_demographics cd_returns_returning
    ON wr.wr_returning_cdemo_sk = cd_returns_returning.cd_demo_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_store_closed.d_year,
    d_return.d_year
ORDER BY
    s.s_store_id,
    d_sales.d_year,
    d_sales.d_month_seq
