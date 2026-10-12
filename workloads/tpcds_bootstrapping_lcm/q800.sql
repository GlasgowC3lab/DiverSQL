WITH daily_returns AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        s.s_state,
        s.s_city,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand
    FROM date_dim d
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
)
SELECT
    dr.d_year,
    dr.d_quarter_name,
    dr.s_state,
    dr.s_city,
    dr.w_warehouse_name,
    SUM(dr.wr_return_amt) AS total_return_amount,
    SUM(dr.wr_return_quantity) AS total_return_qty,
    SUM(dr.wr_net_loss) AS total_net_loss,
    SUM(dr.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(dr.wr_return_amt) AS avg_return_amount,
    CAST(SUM(dr.inv_quantity_on_hand) AS double) / NULLIF(SUM(dr.wr_return_quantity), 0) AS inventory_to_return_ratio,
    ROW_NUMBER() OVER (PARTITION BY dr.w_warehouse_name ORDER BY SUM(dr.wr_return_amt) DESC) AS warehouse_return_rank
FROM daily_returns dr
GROUP BY
    dr.d_year,
    dr.d_quarter_name,
    dr.s_state,
    dr.s_city,
    dr.w_warehouse_name
HAVING SUM(dr.wr_return_amt) > 500
ORDER BY dr.d_year, dr.d_quarter_name, total_return_amount DESC
LIMIT 100
