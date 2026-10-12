SELECT
    i.i_category,
    d_sold.d_year,
    d_sold.d_moy AS month_of_year,
    s.s_state,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(cs.cs_quantity) AS avg_quantity,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
    CASE 
        WHEN SUM(cs.cs_net_paid) > 0 THEN SUM(cs.cs_ext_discount_amt) / SUM(cs.cs_net_paid)
        ELSE 0
    END AS discount_rate,
    CASE 
        WHEN SUM(cs.cs_net_paid) > 0 THEN (SUM(cs.cs_net_paid) - SUM(wr.wr_return_amt)) / SUM(cs.cs_net_paid)
        ELSE 0
    END AS net_sales_factor,
    SUM(wr.wr_return_amt) FILTER (WHERE d_return.d_year = d_sold.d_year) AS return_amount_same_year,
    SUM(wr.wr_return_amt) FILTER (WHERE d_return.d_year <> d_sold.d_year) AS return_amount_diff_year
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2005
GROUP BY i.i_category, d_sold.d_year, d_sold.d_moy, s.s_state
HAVING COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY total_net_paid DESC
LIMIT 100
