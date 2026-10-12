SELECT
    c.cc_country,
    c.cc_state,
    c.cc_division * 10 AS division_scaled,
    s.s_city,
    d_return.d_year,
    d_return.d_month_seq,
    DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date) AS open_to_closed_days,
    DATE_DIFF('day', d_cc_closed.d_date, d_wp_access.d_date) AS page_lifetime_days,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN wp.wp_type = 'Product' THEN 1 ELSE 0 END) AS product_page_visits,
    SUM(CASE WHEN wp.wp_type <> 'Product' THEN 1 ELSE 0 END) AS other_page_visits,
    SUM(CASE WHEN s.s_floor_space > 2000 THEN sr.sr_net_loss ELSE 0 END) AS net_loss_high_floor,
    COUNT(*) FILTER (WHERE d_return.d_weekend = 'Y') AS weekend_returns,
    SUM(sr.sr_net_loss) / NULLIF(SUM(sr.sr_return_quantity), 0) AS avg_loss_per_item
FROM call_center c
JOIN date_dim d_cc_closed
    ON c.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON c.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE c.cc_tax_percentage > 5.0
  AND s.s_tax_percentage < 7.5
  AND d_return.d_year BETWEEN 2015 AND 2020
GROUP BY
    c.cc_country,
    c.cc_state,
    c.cc_division * 10,
    s.s_city,
    d_return.d_year,
    d_return.d_month_seq,
    DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date),
    DATE_DIFF('day', d_cc_closed.d_date, d_wp_access.d_date)
HAVING SUM(sr.sr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 100
