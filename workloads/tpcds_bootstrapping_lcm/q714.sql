SELECT
    customer.c_customer_id,
    customer.c_birth_country,
    CASE 
        WHEN customer.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN customer.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN customer.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS birth_quarter,
    store.s_state,
    d_sales.d_year AS sales_year,
    d_store_closed.d_year AS store_closed_year,
    SUM(store_sales.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(web_returns.wr_net_loss, 0)) AS total_return_loss,
    SUM(store_sales.ss_net_profit) - SUM(COALESCE(web_returns.wr_net_loss, 0)) AS net_profit_after_returns,
    (SUM(store_sales.ss_net_profit) - SUM(COALESCE(web_returns.wr_net_loss, 0))) / NULLIF(SUM(store_sales.ss_net_profit), 0) * 100 AS net_profit_margin_percent,
    AVG(date_diff('day', d_sales.d_date, d_store_closed.d_date)) AS avg_days_between_sale_and_store_close,
    COUNT(DISTINCT store_sales.ss_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT web_returns.wr_item_sk) AS distinct_items_returned
FROM customer
JOIN store_sales 
    ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN store 
    ON store_sales.ss_store_sk = store.s_store_sk
JOIN date_dim AS d_sales 
    ON store_sales.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim AS d_store_closed 
    ON store.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN web_returns 
    ON web_returns.wr_refunded_customer_sk = customer.c_customer_sk
LEFT JOIN date_dim AS d_return 
    ON web_returns.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
GROUP BY
    customer.c_customer_id,
    customer.c_birth_country,
    CASE 
        WHEN customer.c_birth_month BETWEEN 1 AND 3 THEN 'Q1'
        WHEN customer.c_birth_month BETWEEN 4 AND 6 THEN 'Q2'
        WHEN customer.c_birth_month BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    store.s_state,
    d_sales.d_year,
    d_store_closed.d_year
HAVING SUM(store_sales.ss_net_profit) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
