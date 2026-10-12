WITH wp_creation_agg AS (
    SELECT
        dd.d_year AS year,
        dd.d_month_seq AS month,
        COUNT(*) AS wp_created_cnt,
        AVG(wp.wp_image_count) AS avg_image_count_created,
        AVG(wp.wp_link_count) AS avg_link_count_created
    FROM web_page wp
    JOIN date_dim dd ON wp.wp_creation_date_sk = dd.d_date_sk
    GROUP BY dd.d_year, dd.d_month_seq
),
wp_access_agg AS (
    SELECT
        dd.d_year AS year,
        dd.d_month_seq AS month,
        COUNT(*) AS wp_accessed_cnt,
        AVG(wp.wp_image_count) AS avg_image_count_accessed,
        AVG(wp.wp_link_count) AS avg_link_count_accessed
    FROM web_page wp
    JOIN date_dim dd ON wp.wp_access_date_sk = dd.d_date_sk
    GROUP BY dd.d_year, dd.d_month_seq
)
SELECT
    s.s_store_id,
    dd_ret.d_year AS return_year,
    CASE
        WHEN dd_ret.d_month_seq IN (12, 1, 2) THEN 'Winter'
        WHEN dd_ret.d_month_seq IN (3, 4, 5) THEN 'Spring'
        WHEN dd_ret.d_month_seq IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS return_season,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(sr.sr_store_credit) AS total_store_credit,
    COALESCE(wc.wp_created_cnt, 0) AS web_pages_created,
    COALESCE(wc.avg_image_count_created, 0) AS avg_images_created,
    COALESCE(wa.wp_accessed_cnt, 0) AS web_pages_accessed,
    COALESCE(wa.avg_image_count_accessed, 0) AS avg_images_accessed,
    CASE
        WHEN MAX(dd_closed.d_date) IS NULL OR MAX(dd_closed.d_date) > CURRENT_DATE THEN 'Open'
        ELSE 'Closed'
    END AS store_status
FROM store_returns sr
JOIN date_dim dd_ret ON sr.sr_returned_date_sk = dd_ret.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim dd_closed ON s.s_closed_date_sk = dd_closed.d_date_sk
LEFT JOIN wp_creation_agg wc ON wc.year = dd_ret.d_year AND wc.month = dd_ret.d_month_seq
LEFT JOIN wp_access_agg wa ON wa.year = dd_ret.d_year AND wa.month = dd_ret.d_month_seq
WHERE dd_ret.d_year BETWEEN 2015 AND 2020
GROUP BY
    s.s_store_id,
    dd_ret.d_year,
    CASE
        WHEN dd_ret.d_month_seq IN (12, 1, 2) THEN 'Winter'
        WHEN dd_ret.d_month_seq IN (3, 4, 5) THEN 'Spring'
        WHEN dd_ret.d_month_seq IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END,
    wc.wp_created_cnt,
    wc.avg_image_count_created,
    wa.wp_accessed_cnt,
    wa.avg_image_count_accessed
HAVING COUNT(DISTINCT sr.sr_ticket_number) > 10
ORDER BY s.s_store_id, return_year, return_season
