SELECT
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
    SUM(cs.cs_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_sales_after_returns,
    SUM(cs.cs_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_profit_after_returns,
    AVG(cs.cs_ext_tax) AS avg_tax_per_sale,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year = 2020
  AND s.s_state = 'TX'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY net_sales_after_returns DESC
LIMIT 100
