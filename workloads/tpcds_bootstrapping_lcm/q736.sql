SELECT
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    ws.web_name AS website_name,
    ws.web_city AS website_city,
    wp.wp_type AS page_type,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(d_ret.d_date) AS earliest_return_date,
    MAX(d_ws_close.d_date) AS latest_site_close_date,
    MAX(d_wp_access.d_date) AS latest_page_access_date,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(cr.cr_net_loss) DESC) AS store_loss_rank
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
GROUP BY
    s.s_store_name,
    s.s_city,
    ws.web_name,
    ws.web_city,
    wp.wp_type,
    d_ret.d_year,
    d_ret.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
