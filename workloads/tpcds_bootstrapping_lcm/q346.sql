SELECT
    cc.cc_division,
    s.s_state,
    d_closed.d_year,
    d_closed.d_quarter_name,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_fee) AS total_fees,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    AVG(date_diff('day', d_open.d_date, d_closed.d_date)) AS avg_operational_days,
    SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_quantity), 0) AS loss_per_return_qty,
    CASE
        WHEN SUM(wr.wr_net_loss) > 50000 THEN 'HIGH'
        ELSE 'LOW'
    END AS loss_category
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_closed.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_closed.d_date_sk
WHERE d_closed.d_year BETWEEN 2000 AND 2005
GROUP BY
    cc.cc_division,
    s.s_state,
    d_closed.d_year,
    d_closed.d_quarter_name
HAVING SUM(wr.wr_return_quantity) > 20
ORDER BY total_net_loss DESC
LIMIT 100
