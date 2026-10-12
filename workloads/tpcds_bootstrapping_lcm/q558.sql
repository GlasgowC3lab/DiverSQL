SELECT
    s.s_city,
    s.s_state,
    d_cr.d_year,
    d_cr.d_month_seq,
    d_wp_creation.d_current_month AS page_creation_month,
    d_wp_access.d_current_month AS page_access_month,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    AVG(wp.wp_image_count) AS avg_image_count,
    AVG(wp.wp_link_count) AS avg_link_count,
    (SUM(cr.cr_fee) + SUM(wr.wr_fee)) AS total_fees,
    CASE
        WHEN COUNT(DISTINCT cr.cr_order_number) = 0 THEN NULL
        ELSE CAST(COUNT(DISTINCT wr.wr_order_number) AS double) / COUNT(DISTINCT cr.cr_order_number)
    END AS web_to_catalog_return_ratio,
    ROW_NUMBER() OVER (PARTITION BY s.s_city ORDER BY SUM(wr.wr_net_loss) DESC) AS city_rank_by_web_loss
FROM catalog_returns cr
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_city,
    s.s_state,
    d_cr.d_year,
    d_cr.d_month_seq,
    d_wp_creation.d_current_month,
    d_wp_access.d_current_month
HAVING SUM(cr.cr_net_loss + wr.wr_net_loss) > 0
ORDER BY web_net_loss DESC
LIMIT 100
