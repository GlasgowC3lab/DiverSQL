WITH wp_agg AS (
    SELECT
        dcre.d_date_sk AS creation_date_sk,
        dcre.d_date AS creation_date,
        SUM(wp.wp_image_count) AS total_image_count,
        SUM(wp.wp_link_count) AS total_link_count,
        AVG(date_diff('day', dcre.d_date, dacc.d_date)) AS avg_days_to_access
    FROM web_page wp
    JOIN date_dim dcre ON wp.wp_creation_date_sk = dcre.d_date_sk
    JOIN date_dim dacc ON wp.wp_access_date_sk = dacc.d_date_sk
    GROUP BY dcre.d_date_sk, dcre.d_date
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ds.d_year AS sales_year,
    ds.d_month_seq AS sales_month_seq,
    ds.d_date AS sales_date,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
    AVG(ss.ss_sales_price) AS avg_store_sales_price,
    AVG(cs.cs_sales_price) AS avg_catalog_sales_price,
    COALESCE(wp_agg.total_image_count, 0) AS total_image_count,
    COALESCE(wp_agg.total_link_count, 0) AS total_link_count,
    COALESCE(wp_agg.avg_days_to_access, 0) AS avg_days_to_access,
    dc.d_date AS store_closed_date,
    dsh.d_date AS catalog_ship_date
FROM store_sales ss
JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh ON cs.cs_ship_date_sk = dsh.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim dc ON s.s_closed_date_sk = dc.d_date_sk
LEFT JOIN wp_agg ON wp_agg.creation_date_sk = ds.d_date_sk
WHERE ds.d_year = 2021
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ds.d_year,
    ds.d_month_seq,
    ds.d_date,
    dc.d_date,
    dsh.d_date,
    wp_agg.total_image_count,
    wp_agg.total_link_count,
    wp_agg.avg_days_to_access
ORDER BY total_store_net_paid DESC
LIMIT 100
