WITH aggregated AS (
    SELECT
        s.s_city AS store_city,
        s.s_state AS store_state,
        cp.cp_type AS catalog_page_type,
        cp.cp_department AS catalog_department,
        wp.wp_type AS web_page_type,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wp.wp_char_count) AS avg_char_count,
        SUM(wp.wp_image_count) AS total_image_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        s.s_city,
        s.s_state,
        cp.cp_type,
        cp.cp_department,
        wp.wp_type,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    store_city,
    store_state,
    catalog_page_type,
    catalog_department,
    web_page_type,
    return_year,
    return_month,
    distinct_orders,
    total_return_quantity,
    total_return_amount,
    total_net_loss,
    avg_char_count,
    total_image_count,
    distinct_web_pages,
    ROW_NUMBER() OVER (PARTITION BY store_city ORDER BY total_return_amount DESC) AS city_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
