SELECT
    s.s_store_id,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amt,
    COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_qty_on_hand,
    ROUND(SUM(cs.cs_net_paid) - COALESCE(SUM(wr.wr_return_amt), 0), 2) AS net_sales_after_returns,
    d_sold.d_year,
    d_sold.d_month_seq
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    s.s_store_id,
    d_sold.d_date,
    d_ship.d_date,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY net_sales_after_returns DESC
LIMIT 100
