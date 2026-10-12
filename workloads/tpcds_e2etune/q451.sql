WITH page_info AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_char_count,
        wp.wp_image_count,
        wp.wp_link_count,
        wp.wp_type,
        wp.wp_creation_date_sk,
        wp.wp_customer_sk,
        d.d_year,
        d.d_quarter_name,
        d.d_holiday,
        c.c_current_hdemo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2022
      AND d.d_quarter_name = 'Q4'
),
aggregated AS (
    SELECT
        p.ib_lower_bound,
        p.ib_upper_bound,
        COUNT(*) AS total_pages,
        AVG(p.wp_char_count) AS avg_char_count,
        AVG(p.wp_image_count) AS avg_image_count,
        SUM(p.wp_link_count) AS total_links,
        SUM(CASE WHEN p.d_holiday IS NOT NULL THEN 1 ELSE 0 END) AS holiday_page_count
    FROM page_info p
    GROUP BY p.ib_lower_bound, p.ib_upper_bound
    HAVING COUNT(*) >= 10
)
SELECT
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.total_pages,
    a.avg_char_count,
    a.avg_image_count,
    a.total_links,
    a.holiday_page_count,
    RANK() OVER (ORDER BY a.avg_char_count DESC) AS char_count_rank
FROM aggregated a
ORDER BY char_count_rank
LIMIT 50
