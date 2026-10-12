SELECT
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    i.i_category,
    i.i_brand,
    i.i_item_id,
    s.s_store_name,
    s.s_state,
    SUM(wr.wr_return_quantity) AS total_return_qty,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    CASE
        WHEN SUM(inv.inv_quantity_on_hand) = 0 THEN NULL
        ELSE SUM(wr.wr_return_quantity) * 1.0 / SUM(inv.inv_quantity_on_hand)
    END AS return_inventory_ratio,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    AVG(i.i_current_price) AS avg_current_price,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost
FROM date_dim d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND s.s_state IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    i.i_category,
    i.i_brand,
    i.i_item_id,
    s.s_store_name,
    s.s_state
HAVING SUM(wr.wr_return_quantity) >= 10
ORDER BY total_net_loss DESC
LIMIT 200
