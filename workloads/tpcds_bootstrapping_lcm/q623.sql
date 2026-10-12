SELECT
    s.s_store_name,
    s.s_state,
    ws.web_name,
    ws.web_market_manager,
    d_ret.d_year,
    COUNT(cr.cr_order_number)            AS num_returns,
    SUM(cr.cr_return_amount)             AS total_return_amount,
    SUM(cr.cr_net_loss)                  AS total_net_loss,
    AVG(DATE_DIFF('day', d_ret.d_date, d_ws_close.d_date)) AS avg_days_to_site_close,
    AVG(DATE_DIFF('day', d_ret.d_date, d_wp_access.d_date)) AS avg_days_to_page_access
FROM catalog_returns cr
JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
      ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_ws_close
      ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN web_page wp
      ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_wp_access
      ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cr.cr_net_loss > 0
GROUP BY
    s.s_store_name,
    s.s_state,
    ws.web_name,
    ws.web_market_manager,
    d_ret.d_year
ORDER BY total_net_loss DESC
LIMIT 100
