SELECT
    d1.d_year AS return_year,
    s.s_state,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    AVG(CASE WHEN s.s_gmt_offset > 0 THEN sr.sr_net_loss END) AS avg_positive_gmt_loss,
    SUM(wp.wp_image_count) AS total_images,
    COUNT(*) FILTER (WHERE sr.sr_fee > 0) AS fee_count,
    AVG(CASE WHEN d2.d_date IS NOT NULL THEN DATE_DIFF('day', d2.d_date, d1.d_date) END) AS avg_days_between_closed_and_return,
    DATE_TRUNC('month', d1.d_date) AS month_start
FROM date_dim d1
JOIN store_returns sr ON sr.sr_returned_date_sk = d1.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN inventory i ON i.inv_date_sk = d1.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d1.d_date_sk
LEFT JOIN date_dim d2 ON s.s_closed_date_sk = d2.d_date_sk
WHERE d1.d_year BETWEEN 2015 AND 2020
  AND s.s_state IS NOT NULL
GROUP BY d1.d_year, s.s_state, DATE_TRUNC('month', d1.d_date)
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_inventory DESC
LIMIT 100
