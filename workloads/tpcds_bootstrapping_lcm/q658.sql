SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
    (SUM(cr.cr_return_amount) + SUM(wr.wr_return_amt)) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS return_amount_per_inventory,
    CASE 
        WHEN SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0 THEN 'Loss'
        ELSE 'Profit'
    END AS loss_or_profit
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY d.d_year, d.d_month_seq
