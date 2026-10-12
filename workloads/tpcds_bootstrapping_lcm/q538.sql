WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d_sales.d_date,
        d_sales.d_day_name,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(*) AS total_transactions
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    GROUP BY
        ss.ss_store_sk,
        d_sales.d_date,
        d_sales.d_day_name,
        t.t_hour
),
wp_creation_agg AS (
    SELECT
        d_creation.d_date AS date,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
        COALESCE(SUM(wp.wp_image_count), 0) AS images_created,
        COALESCE(SUM(wp.wp_link_count), 0) AS links_created
    FROM web_page wp
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    GROUP BY d_creation.d_date
),
wp_access_agg AS (
    SELECT
        d_access.d_date AS date,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_accessed,
        COALESCE(SUM(wp.wp_image_count), 0) AS images_accessed,
        COALESCE(SUM(wp.wp_link_count), 0) AS links_accessed
    FROM web_page wp
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY d_access.d_date
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sa.d_date,
    sa.d_day_name,
    sa.t_hour,
    sa.total_sales_amount,
    sa.total_net_profit,
    sa.avg_sales_price,
    sa.total_transactions,
    COALESCE(wc.pages_created, 0) AS pages_created_on_date,
    COALESCE(wc.images_created, 0) AS images_created_on_date,
    COALESCE(wc.links_created, 0) AS links_created_on_date,
    COALESCE(wa.pages_accessed, 0) AS pages_accessed_on_date,
    COALESCE(wa.images_accessed, 0) AS images_accessed_on_date,
    COALESCE(wa.links_accessed, 0) AS links_accessed_on_date,
    d_closure.d_date AS store_closed_date,
    d_closure.d_holiday AS store_closed_holiday
FROM sales_agg sa
JOIN store s
    ON sa.store_sk = s.s_store_sk
LEFT JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
LEFT JOIN wp_creation_agg wc
    ON sa.d_date = wc.date
LEFT JOIN wp_access_agg wa
    ON sa.d_date = wa.date
ORDER BY sa.total_sales_amount DESC
LIMIT 100
