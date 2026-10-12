SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_sales_discount,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_net_loss,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_items_returned,
    AVG(t_sold.t_hour) AS avg_sale_hour,
    AVG(t_return.t_hour) AS avg_return_hour
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ship.d_date_sk
JOIN time_dim t_return
    ON wr.wr_returned_time_sk = t_return.t_time_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY
    d_sold.d_year,
    d_sold.d_month_seq,
    total_sales_net_paid DESC
