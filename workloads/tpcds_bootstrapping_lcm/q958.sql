SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_week_seq,
    s.s_store_id,
    s.s_state,
    s.s_country,
    hd.hd_buy_potential,
    SUM(sr.sr_return_amt)               AS total_return_amount,
    SUM(sr.sr_net_loss)                 AS total_net_loss,
    AVG(sr.sr_store_credit)             AS avg_store_credit,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(wp_c.wp_image_count)            AS total_images_created,
    SUM(wp_c.wp_link_count)             AS total_links_created,
    SUM(wp_a.wp_image_count)            AS total_images_accessed,
    SUM(wp_a.wp_link_count)             AS total_links_accessed,
    d_close.d_date                      AS store_closed_date,
    d_close.d_fy_quarter_seq            AS store_closed_fy_quarter
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_close
    ON s.s_closed_date_sk = d_close.d_date_sk
LEFT JOIN web_page wp_c
    ON wp_c.wp_creation_date_sk = d_ret.d_date_sk
LEFT JOIN web_page wp_a
    ON wp_a.wp_access_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_week_seq,
    s.s_store_id,
    s.s_state,
    s.s_country,
    hd.hd_buy_potential,
    d_close.d_date,
    d_close.d_fy_quarter_seq
ORDER BY total_return_amount DESC
LIMIT 100
