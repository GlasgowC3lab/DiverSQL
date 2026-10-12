SELECT
    s.s_store_name,
    s.s_state,
    dr_return.d_year,
    dr_return.d_month_seq,
    dr_closed.d_current_quarter AS store_closed_quarter,
    dr_access.d_dow AS access_day_of_week,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(wp.wp_char_count) AS avg_page_char_count,
    SUM(wp.wp_image_count) AS total_image_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    CASE 
        WHEN SUM(i.inv_quantity_on_hand) > 0 
        THEN ROUND(SUM(sr.sr_net_loss) / SUM(i.inv_quantity_on_hand), 2) 
        ELSE NULL 
    END AS loss_per_inventory,
    DATE_DIFF('day', MIN(dr_closed.d_date), MIN(dr_return.d_date)) AS days_between_store_closed_and_return,
    DATE_DIFF('day', MIN(dr_return.d_date), MIN(dr_access.d_date)) AS days_between_return_and_page_access
FROM store_returns sr
JOIN date_dim dr_return ON sr.sr_returned_date_sk = dr_return.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr_closed ON s.s_closed_date_sk = dr_closed.d_date_sk
JOIN inventory i ON i.inv_date_sk = dr_return.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = dr_return.d_date_sk
JOIN date_dim dr_access ON wp.wp_access_date_sk = dr_access.d_date_sk
WHERE s.s_state = 'CA'
  AND dr_return.d_year BETWEEN 2015 AND 2020
GROUP BY
    s.s_store_name,
    s.s_state,
    dr_return.d_year,
    dr_return.d_month_seq,
    dr_closed.d_current_quarter,
    dr_access.d_dow
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
