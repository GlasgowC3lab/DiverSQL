SELECT
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END AS month_parity,
    s.s_state,
    COALESCE(d_closed.d_year, -1) AS closed_year,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    SUM(sr.sr_net_loss) AS total_store_loss,
    SUM(wr.wr_net_loss) AS total_web_loss,
    COUNT(*) AS total_records,
    (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) / NULLIF(SUM(i.inv_quantity_on_hand), 0) AS loss_per_inventory,
    COUNT(DISTINCT CASE WHEN d.d_holiday = 'Y' THEN sr.sr_ticket_number END) AS holiday_store_tickets,
    COUNT(DISTINCT CASE WHEN d.d_holiday = 'Y' THEN wr.wr_order_number END) AS holiday_web_orders
FROM date_dim d
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2022
GROUP BY
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq % 2 = 0 THEN 'EvenMonth' ELSE 'OddMonth' END,
    s.s_state,
    d_closed.d_year
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY d.d_year DESC, d.d_month_seq, s.s_state
LIMIT 100
