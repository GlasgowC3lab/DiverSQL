SELECT
    d_sold.d_date AS sold_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_date AS ship_date,
    date_diff('day', d_sold.d_date, d_ship.d_date) AS shipping_delay_days,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    (SUM(cs.cs_net_paid) - SUM(wr.wr_return_amt)) AS net_sales_after_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT s.s_store_sk) AS stores_closed,
    RANK() OVER (ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank
FROM
    catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_date
ORDER BY
    total_net_paid DESC
LIMIT 100
