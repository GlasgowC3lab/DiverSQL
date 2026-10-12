SELECT
    d.d_year,
    d.d_quarter_seq,
    i.i_category,
    s.s_state,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amt,
    CASE
        WHEN SUM(inv.inv_quantity_on_hand) > 0 THEN
            SUM(wr.wr_return_quantity) / SUM(inv.inv_quantity_on_hand)
        ELSE NULL
    END AS return_to_inventory_ratio,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    CASE
        WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END AS month_parity
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    i.i_category,
    s.s_state,
    CASE
        WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth'
        ELSE 'OddMonth'
    END
HAVING SUM(wr.wr_return_quantity) > 0
ORDER BY d.d_year, d.d_quarter_seq, i.i_category
