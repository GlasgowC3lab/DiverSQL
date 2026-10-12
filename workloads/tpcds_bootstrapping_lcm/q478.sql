SELECT
    s.s_store_id,
    s.s_store_name,
    d_sr.d_year,
    d_sr.d_month_seq,
    CASE
        WHEN d_sr.d_month_seq IN (11, 12) THEN 'Holiday Season'
        ELSE 'Regular Season'
    END AS season,
    d_store.d_current_month AS store_closed_month,
    d_store.d_year AS store_closed_year,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(sr.sr_fee) AS avg_store_return_fee,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    AVG(wr.wr_fee) AS avg_web_return_fee,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    SUM(i.inv_quantity_on_hand) / NULLIF(COUNT(DISTINCT i.inv_item_sk), 0) AS avg_inventory_per_item,
    (SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) AS combined_return_amt,
    (SUM(sr.sr_return_amt) / NULLIF(SUM(wr.wr_return_amt), 0)) AS store_to_web_return_ratio
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN inventory i
    ON i.inv_date_sk = d_sr.d_date_sk
LEFT JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
WHERE d_sr.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sr.d_year,
    d_sr.d_month_seq,
    CASE
        WHEN d_sr.d_month_seq IN (11, 12) THEN 'Holiday Season'
        ELSE 'Regular Season'
    END,
    d_store.d_current_month,
    d_store.d_year
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY combined_return_amt DESC
LIMIT 50
