SELECT
    s.s_store_id,
    s.s_city,
    d_sales.d_year,
    d_sales.d_month_seq,
    cd_sales.cd_gender,
    cd_sales.cd_marital_status,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT cd_refunded.cd_demo_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT cd_returning.cd_demo_sk) AS distinct_returning_customers,
    d_store.d_current_month AS store_closed_month,
    d_return.d_day_name AS return_day_name
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer_demographics cd_sales
    ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd_sales.cd_demo_sk
    AND wr.wr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    d_sales.d_year,
    d_sales.d_month_seq,
    cd_sales.cd_gender,
    cd_sales.cd_marital_status,
    d_store.d_current_month,
    d_return.d_day_name
ORDER BY total_sales_amount DESC
LIMIT 100
