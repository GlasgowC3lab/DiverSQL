WITH cr_agg AS (
    SELECT
        cr_returned_date_sk AS date_sk,
        COUNT(*) AS returns_cnt,
        SUM(cr_net_loss) AS total_net_loss,
        AVG(cr_return_quantity) AS avg_return_qty,
        SUM(cr_fee) AS total_fee
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
store_agg AS (
    SELECT
        s_closed_date_sk AS date_sk,
        SUM(s_floor_space) AS total_floor_space,
        COUNT(*) AS closed_stores_cnt,
        AVG(s_number_employees) AS avg_employees
    FROM store
    GROUP BY s_closed_date_sk
),
web_page_creation_agg AS (
    SELECT
        wp_creation_date_sk AS date_sk,
        COUNT(*) AS pages_created_cnt,
        AVG(wp_image_count) AS avg_image_cnt,
        SUM(wp_char_count) AS total_char_cnt_created
    FROM web_page
    GROUP BY wp_creation_date_sk
),
web_page_access_agg AS (
    SELECT
        wp_access_date_sk AS date_sk,
        COUNT(*) AS pages_accessed_cnt,
        AVG(wp_link_count) AS avg_link_cnt,
        SUM(wp_char_count) AS total_char_cnt_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(cr.total_net_loss, 0) AS total_net_loss,
    COALESCE(st.total_floor_space, 0) AS total_floor_space,
    COALESCE(wc.pages_created_cnt, 0) AS pages_created_cnt,
    COALESCE(wa.pages_accessed_cnt, 0) AS pages_accessed_cnt,
    COALESCE(wc.avg_image_cnt, 0) AS avg_image_cnt,
    COALESCE(wa.avg_link_cnt, 0) AS avg_link_cnt,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cr.total_net_loss, 0) DESC) AS loss_rank
FROM date_dim d
LEFT JOIN cr_agg cr ON cr.date_sk = d.d_date_sk
LEFT JOIN store_agg st ON st.date_sk = d.d_date_sk
LEFT JOIN web_page_creation_agg wc ON wc.date_sk = d.d_date_sk
LEFT JOIN web_page_access_agg wa ON wa.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
ORDER BY loss_rank
LIMIT 100
