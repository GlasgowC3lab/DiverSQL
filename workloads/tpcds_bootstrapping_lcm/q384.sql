SELECT
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month,
    s.s_store_name,
    i_sales.i_category,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cs.cs_quantity) AS total_sales_quantity,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(cs.cs_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_profit,
    CASE
        WHEN SUM(cs.cs_quantity) = 0 THEN 0
        ELSE SUM(COALESCE(wr.wr_return_quantity, 0)) * 100.0 / SUM(cs.cs_quantity)
    END AS return_rate_percent,
    SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS avg_discount_rate,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i_sales
    ON cs.cs_item_sk = i_sales.i_item_sk
LEFT JOIN web_returns wr
    ON cs.cs_order_number = wr.wr_order_number
    AND cs.cs_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN item i_returns
    ON wr.wr_item_sk = i_returns.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    i_sales.i_category
HAVING
    SUM(cs.cs_ext_sales_price) > 1000
ORDER BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    i_sales.i_category
