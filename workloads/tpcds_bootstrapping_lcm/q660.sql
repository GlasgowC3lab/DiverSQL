SELECT
    d_sales.d_current_year AS year,
    CASE
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_ext_sales_price) AS gross_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_quantity) AS total_units_sold,
    SUM(ss.ss_net_profit) AS gross_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_returns_amount,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_units,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_sales,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit,
    ROUND(
        100.0 * (SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0))
        / NULLIF(SUM(ss.ss_ext_sales_price), 0), 2
    ) AS net_profit_margin_pct,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
    MAX(d_closed.d_current_year) AS store_closed_year
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sales.d_current_year BETWEEN '2019' AND '2021'
GROUP BY
    d_sales.d_current_year,
    CASE
        WHEN d_sales.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sales.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sales.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    s.s_store_name,
    i.i_category
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY net_sales DESC
LIMIT 100
