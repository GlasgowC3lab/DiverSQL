SELECT
    d_ret.d_date AS return_date,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    s.s_store_id,
    s.s_state,
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.wp_url,
    date_diff('day', d_wp_creation.d_date, d_wp_access.d_date) AS page_creation_to_access_days,
    date_diff('day', d_wp_creation.d_date, d_ret.d_date) AS page_age_at_return_days,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_net_loss) AS web_net_loss
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE s.s_state = 'CA'
  AND wp.wp_type = 'product'
  AND d_ret.d_year = 2022
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_state,
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.wp_url,
    d_wp_creation.d_date,
    d_wp_access.d_date
ORDER BY d_ret.d_date DESC
