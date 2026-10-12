SELECT
    s.s_store_id,
    s.s_store_name,
    ds_sales.d_year,
    ds_sales.d_month_seq AS month_seq,
    MIN(ds_closed.d_date) AS store_closed_date,
    MAX(ds_ship.d_date) AS latest_ship_date,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_web_pages,
    AVG(date_diff('day', dp_creation.d_date, dp_access.d_date)) AS avg_page_access_lag_days,
    AVG(wp.wp_image_count) AS avg_image_count_per_page,
    SUM(wp.wp_link_count) AS total_link_count
FROM store_sales ss
JOIN date_dim ds_sales
    ON ss.ss_sold_date_sk = ds_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim ds_closed
    ON s.s_closed_date_sk = ds_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = ds_sales.d_date_sk
JOIN date_dim ds_ship
    ON ws.ws_ship_date_sk = ds_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dp_creation
    ON wp.wp_creation_date_sk = dp_creation.d_date_sk
JOIN date_dim dp_access
    ON wp.wp_access_date_sk = dp_access.d_date_sk
WHERE ds_sales.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ds_sales.d_year,
    ds_sales.d_month_seq
ORDER BY total_store_sales DESC
LIMIT 100
