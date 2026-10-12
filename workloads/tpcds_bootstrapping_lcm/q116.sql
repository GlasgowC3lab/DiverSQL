SELECT
    s.s_store_name,
    s.s_city,
    d_sales.d_year AS sales_year,
    d_closed.d_date AS store_closed_date,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(ss.ss_net_profit) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_profit_after_returns,
    (SUM(COALESCE(wr.wr_return_amt, 0)) / NULLIF(SUM(ss.ss_net_profit), 0)) AS return_rate,
    AVG(cd_sales.cd_purchase_estimate) AS avg_purchase_estimate_buyers,
    AVG(cd_refunded.cd_purchase_estimate) AS avg_purchase_estimate_refunded,
    AVG(cd_returning.cd_purchase_estimate) AS avg_purchase_estimate_returning,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    COUNT(DISTINCT wr.wr_refunded_customer_sk) AS distinct_refunded_customers
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd_sales
    ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
LEFT JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE d_sales.d_year BETWEEN 2000 AND 2005
GROUP BY
    s.s_store_name,
    s.s_city,
    d_sales.d_year,
    d_closed.d_date
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY s.s_store_name, d_sales.d_year
