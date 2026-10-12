SELECT
    cp.cp_department,
    d_ret.d_year,
    d_ret.d_current_month,
    CASE
        WHEN d_ret.d_quarter_seq IN (1, 2) THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
    COALESCE(SUM(s.s_floor_space), 0) AS total_floor_space_closed_stores,
    COUNT(DISTINCT ws.web_site_id) AS distinct_web_sites_opened,
    COUNT(DISTINCT ws2.web_site_id) AS distinct_web_sites_closed,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_net_loss), 0) AS return_to_loss_ratio,
    AVG(date_diff('day', d_start.d_date, d_end.d_date)) AS avg_page_duration_days
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
LEFT JOIN web_site ws2
    ON ws2.web_close_date_sk = d_ret.d_date_sk
WHERE cp.cp_type = 'CATALOG'
GROUP BY
    cp.cp_department,
    d_ret.d_year,
    d_ret.d_current_month,
    CASE
        WHEN d_ret.d_quarter_seq IN (1, 2) THEN 'H1'
        ELSE 'H2'
    END
HAVING SUM(cr.cr_return_amount) > 1000
   AND COUNT(DISTINCT cp.cp_catalog_page_id) >= 5
ORDER BY total_net_loss DESC
LIMIT 100
