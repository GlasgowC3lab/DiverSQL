WITH wp_creation AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_type,
        wp.wp_url,
        wp.wp_creation_date_sk AS creation_date_sk,
        dc.d_year AS creation_year,
        dc.d_month_seq AS creation_month,
        COUNT(*) AS page_creation_count
    FROM web_page wp
    JOIN date_dim dc ON wp.wp_creation_date_sk = dc.d_date_sk
    GROUP BY
        wp.wp_web_page_id,
        wp.wp_type,
        wp.wp_url,
        wp.wp_creation_date_sk,
        dc.d_year,
        dc.d_month_seq
),
wp_access AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_access_date_sk AS access_date_sk,
        da.d_year AS access_year,
        da.d_month_seq AS access_month,
        COUNT(*) AS page_access_count
    FROM web_page wp
    JOIN date_dim da ON wp.wp_access_date_sk = da.d_date_sk
    GROUP BY
        wp.wp_web_page_id,
        wp.wp_access_date_sk,
        da.d_year,
        da.d_month_seq
)
SELECT
    dr.d_year,
    dr.d_month_seq,
    s.s_state,
    s.s_city,
    td.t_hour,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(CASE WHEN wp_creation.wp_type = 'product' THEN cr.cr_return_amount ELSE 0 END) AS product_return_amount,
    SUM(CASE WHEN wp_creation.wp_type = 'category' THEN cr.cr_return_amount ELSE 0 END) AS category_return_amount,
    COUNT(DISTINCT wp_creation.wp_web_page_id) AS distinct_pages,
    AVG(wp_creation.creation_year) AS avg_page_creation_year,
    MAX(wp_access.access_year) AS latest_page_access_year
FROM catalog_returns cr
JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
LEFT JOIN wp_creation ON wp_creation.creation_date_sk = dr.d_date_sk
LEFT JOIN wp_access ON wp_access.access_date_sk = dr.d_date_sk
WHERE cr.cr_return_amount > 0
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    s.s_state,
    s.s_city,
    td.t_hour
HAVING COUNT(DISTINCT cr.cr_order_number) > 10
ORDER BY
    dr.d_year DESC,
    dr.d_month_seq,
    s.s_state
