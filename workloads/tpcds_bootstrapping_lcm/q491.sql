SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(i.i_current_price) AS avg_current_price,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    CASE 
        WHEN SUM(wr.wr_return_amt) = 0 THEN 0
        ELSE SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
    END AS net_loss_ratio
FROM date_dim AS d
JOIN web_returns AS wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item AS i
    ON wr.wr_item_sk = i.i_item_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2020
GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, s.s_state
ORDER BY total_return_amount DESC
LIMIT 100
