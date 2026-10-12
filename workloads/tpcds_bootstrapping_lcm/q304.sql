SELECT
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    SUM(cs.cs_quantity) - SUM(wr.wr_return_quantity) AS net_quantity_sold
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_ship.d_month_seq,
    s.s_state,
    s.s_city
ORDER BY total_sales DESC
LIMIT 100
