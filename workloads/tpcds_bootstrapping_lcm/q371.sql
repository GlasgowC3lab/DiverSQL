SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    s.s_state,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    CASE 
        WHEN SUM(inv.inv_quantity_on_hand) > 0 THEN SUM(wr.wr_return_quantity) * 1.0 / SUM(inv.inv_quantity_on_hand)
        ELSE NULL
    END AS return_to_inventory_ratio,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
    ON i.i_item_sk = wr.wr_item_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year >= 2000
GROUP BY d.d_year, d.d_month_seq, i.i_category, s.s_state
HAVING SUM(wr.wr_return_quantity) > 0
ORDER BY d.d_year DESC, d.d_month_seq DESC, total_return_amt DESC
LIMIT 100
