WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        wp.wp_type,
        wp.wp_url,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(wp.wp_image_count) AS total_image_count,
        SUM(wp.wp_link_count) AS total_link_count,
        SUM(CASE WHEN cr.cr_returned_date_sk = wp.wp_creation_date_sk THEN 1 ELSE 0 END) AS returns_on_page_creation,
        SUM(CASE WHEN cr.cr_returned_date_sk = wp.wp_access_date_sk THEN 1 ELSE 0 END) AS returns_on_page_access
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        wp.wp_type,
        wp.wp_url
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    d_year,
    d_month_seq,
    wp_type,
    wp_url,
    distinct_orders,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    total_image_count,
    total_link_count,
    returns_on_page_creation,
    returns_on_page_access,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_return_amount DESC) AS rank_by_return_amount
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
