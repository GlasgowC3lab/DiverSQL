SELECT
    d.d_year,
    FLOOR((d.d_month_seq - 1) / 3) + 1 AS quarter,
    i.i_category,
    s.s_state,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_quantity ELSE 0 END) AS total_return_quantity,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(i.i_current_price) AS avg_current_price,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    SUM(inv.inv_quantity_on_hand * i.i_current_price) AS inventory_value_current_price,
    SUM(inv.inv_quantity_on_hand * i.i_wholesale_cost) AS inventory_value_wholesale_cost,
    SUM(wr.wr_return_amt * s.s_tax_percentage / 100) AS tax_adjusted_return_amount
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY d.d_year, FLOOR((d.d_month_seq - 1) / 3) + 1, i.i_category, s.s_state
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY d.d_year, quarter, i.i_category
LIMIT 100
