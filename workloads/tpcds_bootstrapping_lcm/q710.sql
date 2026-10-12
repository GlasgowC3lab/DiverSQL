WITH
    returns_agg AS (
        SELECT
            d_ret.d_date AS return_date,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(DISTINCT cr.cr_order_number) AS num_returns,
            AVG(cr.cr_return_quantity) AS avg_return_quantity,
            SUM(CASE WHEN cd_ref.cd_gender = 'F' THEN cr.cr_return_amount ELSE 0 END) AS female_refunded_return_amount,
            SUM(CASE WHEN cd_ret.cd_gender = 'M' THEN cr.cr_return_amount ELSE 0 END) AS male_returning_return_amount,
            SUM(cr.cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN date_dim d_ret
            ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN customer_demographics cd_ref
            ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN customer_demographics cd_ret
            ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        WHERE d_ret.d_year = 2022
        GROUP BY d_ret.d_date
    ),
    store_agg AS (
        SELECT
            d_store.d_date AS close_date,
            COUNT(DISTINCT s.s_store_id) AS num_stores_closed,
            SUM(s.s_floor_space) AS total_floor_space_closed
        FROM store s
        JOIN date_dim d_store
            ON s.s_closed_date_sk = d_store.d_date_sk
        WHERE d_store.d_year = 2022
        GROUP BY d_store.d_date
    ),
    web_page_creation_agg AS (
        SELECT
            d_creation.d_date AS creation_date,
            COUNT(DISTINCT wp.wp_web_page_id) AS num_pages_created,
            SUM(wp.wp_image_count) AS total_image_count_created
        FROM web_page wp
        JOIN date_dim d_creation
            ON wp.wp_creation_date_sk = d_creation.d_date_sk
        WHERE d_creation.d_year = 2022
        GROUP BY d_creation.d_date
    ),
    web_page_access_agg AS (
        SELECT
            d_access.d_date AS access_date,
            COUNT(DISTINCT wp.wp_web_page_id) AS num_pages_accessed,
            SUM(wp.wp_link_count) AS total_link_count_accessed
        FROM web_page wp
        JOIN date_dim d_access
            ON wp.wp_access_date_sk = d_access.d_date_sk
        WHERE d_access.d_year = 2022
        GROUP BY d_access.d_date
    )
SELECT
    r.return_date,
    r.total_return_amount,
    r.num_returns,
    r.avg_return_quantity,
    r.female_refunded_return_amount,
    r.male_returning_return_amount,
    r.total_net_loss,
    COALESCE(s.num_stores_closed, 0) AS num_stores_closed,
    COALESCE(s.total_floor_space_closed, 0) AS total_floor_space_closed,
    COALESCE(c.num_pages_created, 0) AS num_pages_created,
    COALESCE(c.total_image_count_created, 0) AS total_image_count_created,
    COALESCE(a.num_pages_accessed, 0) AS num_pages_accessed,
    COALESCE(a.total_link_count_accessed, 0) AS total_link_count_accessed
FROM returns_agg r
LEFT JOIN store_agg s
    ON r.return_date = s.close_date
LEFT JOIN web_page_creation_agg c
    ON r.return_date = c.creation_date
LEFT JOIN web_page_access_agg a
    ON r.return_date = a.access_date
WHERE r.total_return_amount > 1000
ORDER BY r.total_return_amount DESC
LIMIT 100
