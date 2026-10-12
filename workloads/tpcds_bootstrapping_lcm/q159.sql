SELECT
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    w.w_warehouse_name AS warehouse_name,
    w.w_city AS warehouse_city,
    d_ret.d_year AS return_year,
    COUNT(cr.cr_order_number) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(wp.wp_image_count) AS avg_page_image_count,
    AVG(wp.wp_link_count) AS avg_page_link_count,
    d_access.d_year AS access_year,
    RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    w.w_warehouse_name,
    w.w_city,
    d_ret.d_year,
    d_access.d_year
ORDER BY loss_rank
LIMIT 100
