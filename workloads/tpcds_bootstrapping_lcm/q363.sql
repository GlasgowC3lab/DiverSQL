SELECT
    cp.cp_catalog_page_id,
    cp.cp_description,
    cp.cp_type,
    dp_start.d_date AS page_start_date,
    dp_end.d_date AS page_end_date,
    dr.d_date AS return_date,
    ds.d_date AS store_closed_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    wp.wp_char_count,
    dwa.d_date AS web_page_access_date,
    COUNT(cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim dp_start
    ON cp.cp_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end
    ON cp.cp_end_date_sk = dp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dp_start.d_date_sk
JOIN date_dim dwa
    ON wp.wp_access_date_sk = dwa.d_date_sk
WHERE cp.cp_type = 'Catalog'
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_description,
    cp.cp_type,
    dp_start.d_date,
    dp_end.d_date,
    dr.d_date,
    ds.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_market_desc,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    wp.wp_char_count,
    dwa.d_date
ORDER BY total_return_amount DESC
LIMIT 100
