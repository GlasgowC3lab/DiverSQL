WITH daily_sales AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_hdemo_sk AS demo_sk,
        SUM(ss.ss_ext_sales_price) AS daily_sales,
        SUM(ss.ss_ext_discount_amt) AS daily_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_hdemo_sk
),
page_stats AS (
    SELECT
        wp.wp_creation_date_sk AS date_sk,
        AVG(wp.wp_image_count) AS avg_image_count,
        MAX(wp.wp_image_count) AS max_image_count,
        MIN(wp.wp_image_count) AS min_image_count,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
    FROM web_page wp
    GROUP BY wp.wp_creation_date_sk
)
SELECT
    d.d_year,
    d.d_current_quarter,
    d.d_week_seq,
    s.s_store_name,
    s.s_state,
    s.s_market_desc,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    ds.daily_sales,
    ds.daily_discount,
    ds.tickets_sold,
    ps.avg_image_count,
    ps.max_image_count,
    ps.min_image_count,
    ps.distinct_pages,
    d_closed.d_date AS store_closed_date,
    dense_rank() OVER (PARTITION BY d.d_current_quarter ORDER BY ds.daily_sales DESC) AS quarter_store_rank
FROM daily_sales ds
JOIN date_dim d
    ON ds.date_sk = d.d_date_sk
JOIN store s
    ON ds.store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN household_demographics hd
    ON ds.demo_sk = hd.hd_demo_sk
LEFT JOIN page_stats ps
    ON ps.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
  AND s.s_state = 'CA'
ORDER BY ds.daily_sales DESC
LIMIT 100
