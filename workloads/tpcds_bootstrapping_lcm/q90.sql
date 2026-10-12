SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    i.i_category,
    i.i_class,
    s.s_state,
    s.s_city,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_accessed
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_store
    ON d_store.d_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_wp_creation
    ON d_wp_creation.d_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    i.i_category,
    i.i_class,
    s.s_state,
    s.s_city
ORDER BY
    total_net_loss DESC,
    num_returns DESC
