SELECT
    d_sales.d_year AS sales_year,
    d_sales.d_moy AS sales_month,
    s.s_state,
    s.s_city,
    CASE
        WHEN s.s_state = 'CA' THEN 'West Coast'
        WHEN s.s_state = 'NY' THEN 'East Coast'
        ELSE 'Other'
    END AS region_group,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(*) AS total_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_quantity,
    (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0)) AS net_sales_after_returns,
    CASE
        WHEN SUM(ss.ss_quantity) = 0 THEN 0
        ELSE 100.0 * COALESCE(SUM(wr.wr_return_quantity), 0) / NULLIF(SUM(ss.ss_quantity), 0)
    END AS return_quantity_pct,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE 100.0 * SUM(ss.ss_ext_discount_amt) / NULLIF(SUM(ss.ss_ext_sales_price), 0)
    END AS avg_discount_pct,
    CASE
        WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price)
    END AS profit_margin
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_cust_first_sales
    ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
GROUP BY
    d_sales.d_year,
    d_sales.d_moy,
    s.s_state,
    s.s_city,
    CASE
        WHEN s.s_state = 'CA' THEN 'West Coast'
        WHEN s.s_state = 'NY' THEN 'East Coast'
        ELSE 'Other'
    END
ORDER BY net_sales_after_returns DESC
LIMIT 100
