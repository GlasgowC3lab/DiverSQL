SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_number_employees,
    s.s_floor_space,
    d_ret.d_date AS return_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    CASE WHEN d_closed.d_date IS NOT NULL THEN 1 ELSE 0 END AS store_closed_flag,
    d_closed.d_date AS store_closed_date,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_net_loss) / NULLIF(s.s_number_employees, 0) AS net_loss_per_employee,
    SUM(sr.sr_net_loss) / NULLIF(s.s_floor_space, 0) AS net_loss_per_sqft,
    COUNT(*) AS return_cnt,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_fee) AS total_fee,
    COUNT(DISTINCT wp_created.wp_web_page_id) AS pages_created_cnt,
    COUNT(DISTINCT wp_access.wp_web_page_id) AS pages_accessed_cnt,
    COUNT(DISTINCT ws_open.web_site_id) AS sites_opened_cnt,
    COUNT(DISTINCT ws_close.web_site_id) AS sites_closed_cnt
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_page wp_created
    ON wp_created.wp_creation_date_sk = d_ret.d_date_sk
LEFT JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = d_ret.d_date_sk
LEFT JOIN web_site ws_open
    ON ws_open.web_open_date_sk = d_ret.d_date_sk
LEFT JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d_ret.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_number_employees,
    s.s_floor_space,
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_closed.d_date
ORDER BY total_net_loss DESC
LIMIT 100
