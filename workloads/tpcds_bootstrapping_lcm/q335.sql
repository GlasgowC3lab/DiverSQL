SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
    SUM(ss.ss_ext_sales_price) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_profit) AS total_net_profit,
    MAX(ss.ss_net_profit) AS max_net_profit_per_sale,
    MIN(ss.ss_net_profit) AS min_net_profit_per_sale,
    d_store.d_current_day AS store_closed_day,
    d_ship.d_year AS first_ship_year,
    d_first_sales.d_year AS first_sales_year,
    d_last_review.d_year AS last_review_year
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_returning_customer_sk = c.c_customer_sk
    AND wr.wr_returned_date_sk = d_sales.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_first_sales
    ON c.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN date_dim d_last_review
    ON c.c_last_review_date = d_last_review.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_store.d_current_day,
    d_ship.d_year,
    d_first_sales.d_year,
    d_last_review.d_year
ORDER BY net_sales DESC
LIMIT 100
