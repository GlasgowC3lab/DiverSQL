SELECT
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month_seq,
    dr.d_day_name AS return_day_name,
    ds.d_current_day AS store_closed_day,
    ds.d_quarter_name AS store_closed_quarter,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(sr.sr_ticket_number) AS return_transactions,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    t.t_hour,
    t.t_minute,
    t.t_shift,
    t.t_meal_time,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_created,
    SUM(wp.wp_char_count) AS total_char_count,
    MAX(wp.wp_image_count) AS max_image_count,
    dw.d_day_name AS web_page_access_day,
    dw.d_month_seq AS web_page_access_month_seq
FROM store_returns sr
JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim ds ON s.s_closed_date_sk = ds.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = dr.d_date_sk
JOIN date_dim dw ON wp.wp_access_date_sk = dw.d_date_sk
WHERE dr.d_year = 2022
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    dr.d_day_name,
    ds.d_current_day,
    ds.d_quarter_name,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    t.t_hour,
    t.t_minute,
    t.t_shift,
    t.t_meal_time,
    dw.d_day_name,
    dw.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
